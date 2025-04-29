using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Sistema_RRHH.Clases;

namespace Sistema_RRHH
{
    public partial class AjustesEvaluaciones : System.Web.UI.Page
    {
        string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;
        protected void Page_Load(object sender, EventArgs e)
        {

            if (Session["username"] == null)
            {
                Response.Redirect("Login.aspx");
                return;
            }

            Seguridad.VerificarAdmin(this);

            if (!IsPostBack)
            {
                CargarAniosPeriodos();
                int anioActual = DateTime.Now.Year;
                CargarPeriodosPorAnio(anioActual);
                CargarPreguntas();
            }
        }

        /*// Cargar los periodos de evaluación en el CheckBoxList
        private void CargarPeriodos()
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "SELECT id_periodo, CONCAT(anio, ' - Trimestre ', trimestre) as nombre_periodo FROM PeriodosEvaluacion ORDER BY anio, trimestre";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        cblPeriodos.DataSource = reader;
                        cblPeriodos.DataValueField = "id_periodo";
                        cblPeriodos.DataTextField = "nombre_periodo";
                        cblPeriodos.DataBind();
                    }
                }
            }
        }*/

        private void CargarPreguntas()
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = @"
            SELECT 
                p.id_pregunta, 
                p.texto_pregunta, 
                p.seccion,
                STUFF((
                    SELECT ', ' + CONCAT(pe.anio, ' - Trimestre ', pe.trimestre)
                    FROM PreguntasPeriodos pp2
                    INNER JOIN PeriodosEvaluacion pe ON pp2.id_periodo = pe.id_periodo
                    WHERE pp2.id_pregunta = p.id_pregunta
                    FOR XML PATH(''), TYPE
                ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS Periodos
            FROM Preguntas p
            ORDER BY p.id_pregunta;";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    DataTable dt = new DataTable();
                    dt.Load(cmd.ExecuteReader());
                    gvPreguntas.DataSource = dt;
                    gvPreguntas.DataBind();
                }
            }
        }

        protected string FormatPeriodos(string periodos)
        {
            if (string.IsNullOrEmpty(periodos))
                return string.Empty;
            //Separar las entradas por ", " y unir usando un salto de línea HTML
            var items = periodos.Split(new string[] { ", " }, StringSplitOptions.RemoveEmptyEntries);
            return string.Join("<br />", items);
        }


        //Guardar la pregunta y asignarla a los periodos seleccionados
        protected void btnGuardar_Click(object sender, EventArgs e)
        {
            litMensaje.Text = "";
            //Validaciones
            if (string.IsNullOrEmpty(txtPregunta.Text.Trim()))
            {
                litMensaje.Text = "<div class='alert alert-danger'>Ingrese el texto de la pregunta 1.</div>";
                return;
            }
            if (cblPeriodos.SelectedItem == null)
            {
                litMensaje.Text = "<div class='alert alert-danger'>Seleccione al menos un periodo.</div>";
                return;
            }

            int idPregunta = 0;
            //Si estamos en modo edición (hfIdPregunta no está vacío) se hace un UPDATE
            if (!string.IsNullOrEmpty(hfIdPregunta.Value))
            {
                idPregunta = Convert.ToInt32(hfIdPregunta.Value);
                //Actualizar la pregunta en la tabla Preguntas
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    string updatePregunta = "UPDATE Preguntas SET texto_pregunta = @texto, seccion = @seccion WHERE id_pregunta = @idPregunta";
                    using (SqlCommand cmd = new SqlCommand(updatePregunta, conn))
                    {
                        cmd.Parameters.AddWithValue("@texto", txtPregunta.Text.Trim());
                        cmd.Parameters.AddWithValue("@seccion", ddlCategoria.SelectedValue);
                        cmd.Parameters.AddWithValue("@idPregunta", idPregunta);
                        cmd.ExecuteNonQuery();
                    }
                    //Eliminar todas las relaciones existentes para esta pregunta
                    string deleteRelaciones = "DELETE FROM PreguntasPeriodos WHERE id_pregunta = @idPregunta";
                    using (SqlCommand cmdDelete = new SqlCommand(deleteRelaciones, conn))
                    {
                        cmdDelete.Parameters.AddWithValue("@idPregunta", idPregunta);
                        cmdDelete.ExecuteNonQuery();
                    }
                    //Insertar la relación para cada periodo seleccionado en el CheckBoxList
                    foreach (ListItem item in cblPeriodos.Items)
                    {
                        if (item.Selected)
                        {
                            string insertRelacion = "INSERT INTO PreguntasPeriodos (id_pregunta, id_periodo) VALUES (@idPregunta, @idPeriodo)";
                            using (SqlCommand cmdInsert = new SqlCommand(insertRelacion, conn))
                            {
                                cmdInsert.Parameters.AddWithValue("@idPregunta", idPregunta);
                                cmdInsert.Parameters.AddWithValue("@idPeriodo", Convert.ToInt32(item.Value));
                                cmdInsert.ExecuteNonQuery();
                            }
                        }
                    }
                }
            
                litMensaje.Text = "<div class='alert alert-success'>Pregunta actualizada correctamente.</div>";
                hfIdPregunta.Value = ""; //Limpiar modo edición
                LimpiarFormulario();
                CargarPreguntas();
            }
            else
            {
                //Modo inserción: insertar la pregunta en la tabla Preguntas
                int idPeriodo = Convert.ToInt32(cblPeriodos.SelectedValue); 
                                                                           
                List<string> preguntas = new List<string>();
                preguntas.Add(txtPregunta.Text.Trim());  //Pregunta 1 (obligatoria)
                if (!string.IsNullOrEmpty(txtPregunta2.Text.Trim()))
                    preguntas.Add(txtPregunta2.Text.Trim());
                if (!string.IsNullOrEmpty(txtPregunta3.Text.Trim()))
                    preguntas.Add(txtPregunta3.Text.Trim());

                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    foreach (string textoPregunta in preguntas)
                    {
                        
                        //Insertar la pregunta en la tabla Preguntas y obtener el ID generado
                        string queryPregunta = @"
                    INSERT INTO Preguntas (texto_pregunta, seccion)
                    VALUES (@texto, @seccion);
                    SELECT SCOPE_IDENTITY();";
                        using (SqlCommand cmd = new SqlCommand(queryPregunta, conn))
                        {
                            cmd.Parameters.AddWithValue("@texto", textoPregunta);
                            cmd.Parameters.AddWithValue("@seccion", ddlCategoria.SelectedValue);
                            idPregunta = Convert.ToInt32(cmd.ExecuteScalar());
                        }
                        //Insertar la relación en PreguntasPeriodos para cada periodo seleccionado en el CheckBoxList
                        foreach (ListItem item in cblPeriodos.Items)
                        {
                            if (item.Selected)
                            {
                                string queryRelacion = "INSERT INTO PreguntasPeriodos (id_pregunta, id_periodo) VALUES (@id_pregunta, @id_periodo)";
                                using (SqlCommand cmdRel = new SqlCommand(queryRelacion, conn))
                                {
                                    cmdRel.Parameters.AddWithValue("@id_pregunta", idPregunta);
                                    cmdRel.Parameters.AddWithValue("@id_periodo", Convert.ToInt32(item.Value));
                                    cmdRel.ExecuteNonQuery();
                                }
                            }
                        }
                    }
                }
                litMensaje.Text = "<div class='alert alert-success'>Pregunta(s) guardada(s) y asignada(s) correctamente.</div>";
            }

            LimpiarFormulario();
            CargarPreguntas();
        }

        protected void lnkEditar_Click(object sender, EventArgs e)
        {
            //Obtenemos el ID de la pregunta desde el CommandArgument
            int idPregunta = Convert.ToInt32(((LinkButton)sender).CommandArgument);

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();

                //obtener los datos de la pregunta (texto y sección)
                string queryPregunta = @"
            SELECT texto_pregunta, seccion
            FROM Preguntas
            WHERE id_pregunta = @idPregunta";
                using (SqlCommand cmd = new SqlCommand(queryPregunta, conn))
                {
                    cmd.Parameters.AddWithValue("@idPregunta", idPregunta);
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            txtPregunta.Text = reader["texto_pregunta"].ToString();
                            ddlCategoria.SelectedValue = reader["seccion"].ToString();
                        }
                    }
                }

                //obtener los periodos asociados a esta pregunta
                //deseleccionamos todos los items del CheckBoxList
                foreach (ListItem item in cblPeriodos.Items)
                {
                    item.Selected = false;
                }
                string queryPeriodos = "SELECT id_periodo FROM PreguntasPeriodos WHERE id_pregunta = @idPregunta";
                using (SqlCommand cmd = new SqlCommand(queryPeriodos, conn))
                {
                    cmd.Parameters.AddWithValue("@idPregunta", idPregunta);
                    using (SqlDataReader dr = cmd.ExecuteReader())
                    {
                        while (dr.Read())
                        {
                            int idPeriodo = Convert.ToInt32(dr["id_periodo"]);
                            ListItem item = cblPeriodos.Items.FindByValue(idPeriodo.ToString());
                            if (item != null)
                            {
                                item.Selected = true;
                            }
                        }
                    }
                }

                //Indicar en un HiddenField que se está en modo edición
                hfIdPregunta.Value = idPregunta.ToString();
            }
        }

        protected void lnkEliminar_Click(object sender, EventArgs e)
        {
            //Obtenemos el ID de la pregunta desde el CommandArgument
            int idPregunta = Convert.ToInt32(((LinkButton)sender).CommandArgument);

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();

                //eliminamos las relaciones de la pregunta en la tabla PreguntasPeriodos
                string queryRel = "DELETE FROM PreguntasPeriodos WHERE id_pregunta = @idPregunta";
                using (SqlCommand cmdRel = new SqlCommand(queryRel, conn))
                {
                    cmdRel.Parameters.AddWithValue("@idPregunta", idPregunta);
                    cmdRel.ExecuteNonQuery();
                }

                // Opcionalmente eliminar la pregunta completamente de la tabla Preguntas:
                string queryPregunta = "DELETE FROM Preguntas WHERE id_pregunta = @idPregunta";
                using (SqlCommand cmdPregunta = new SqlCommand(queryPregunta, conn))
                {
                    cmdPregunta.Parameters.AddWithValue("@idPregunta", idPregunta);
                    cmdPregunta.ExecuteNonQuery();
                }
            }

            litMensaje.Text = "<div class='alert alert-success'>Pregunta eliminada correctamente.</div>";
            CargarPreguntas();
        }



        protected void btnCancelar_Click(object sender, EventArgs e)
        {
            litMensaje.Text = "";
            LimpiarFormulario();
        }

        private void LimpiarFormulario()
        {
            txtPregunta.Text = "";
            txtPregunta2.Text = "";
            txtPregunta3.Text = "";
            ddlCategoria.SelectedIndex = 0;
            hfIdPregunta.Value = "";
            //Deseleccionar todos los periodos
            foreach (ListItem item in cblPeriodos.Items)
            {
                item.Selected = false;
            }
        }

        private void CargarAniosPeriodos()
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "SELECT DISTINCT anio FROM PeriodosEvaluacion ORDER BY anio";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    SqlDataReader dr = cmd.ExecuteReader();
                    ddlAnios.DataSource = dr;
                    ddlAnios.DataTextField = "anio";
                    ddlAnios.DataValueField = "anio";
                    ddlAnios.DataBind();
                }
            }
            ddlAnios.Items.Insert(0, new ListItem("Seleccione un año", "0"));
        }

        private void CargarPeriodosPorAnio(int anio)
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = @"
            SELECT id_periodo, CONCAT(anio, ' - Trimestre ', trimestre) as nombre_periodo 
            FROM PeriodosEvaluacion 
            WHERE anio = @anio
            ORDER BY trimestre";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@anio", anio);
                    SqlDataReader dr = cmd.ExecuteReader();
                    cblPeriodos.DataSource = dr;
                    cblPeriodos.DataTextField = "nombre_periodo";
                    cblPeriodos.DataValueField = "id_periodo";
                    cblPeriodos.DataBind();
                }
            }
        }

        protected void ddlAnios_SelectedIndexChanged(object sender, EventArgs e)
        {
            int anioSeleccionado = Convert.ToInt32(ddlAnios.SelectedValue);
            if (anioSeleccionado != 0)
            {
                CargarPeriodosPorAnio(anioSeleccionado);
            }
            else
            {
                cblPeriodos.Items.Clear();
            }
        }
        protected void gvPreguntas_PageIndexChanging(object sender, GridViewPageEventArgs e)
        {
            gvPreguntas.PageIndex = e.NewPageIndex;
            CargarPreguntas(); //recargar los datos del grid
        }

    }
}

		
	
