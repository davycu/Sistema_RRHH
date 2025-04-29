using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Sistema_RRHH.Clases;

namespace Sistema_RRHH
{
	public partial class EvaluarEmpleados : System.Web.UI.Page
	{
        string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;
        protected void Page_Load(object sender, EventArgs e)
		{

            Seguridad.VerificarSupervisor(this);

            if (!IsPostBack)
            {
                CargarEvaluacionesPendientes();
                //Mostrar botón resetear/eliminar solo para Admin
                string rol = Session["rol"] != null ? Session["rol"].ToString().ToLower() : "";
                btnResetear.Visible = (rol == "admin");
            }
        }

        private void CargarEvaluacionesPendientes()
        {
            int idSupervisor = Convert.ToInt32(Session["id_empleado"]);
            string rol = Session["rol"] != null ? Session["rol"].ToString().ToLower() : "";
            List<EvaluacionInfo> lista = new List<EvaluacionInfo>();
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                //Se filtran evaluaciones finalizadas que aún no han sido evaluadas por supervisor
                string filtroDepartamento = (rol == "rh" || rol == "admin")
                    ? ""
                    : "AND emp.id_departamento IN (SELECT id_departamento FROM Empleados WHERE id_empleado = @idSupervisor)";

                string query = $@"
                    SELECT e.id_evaluacion, 
                           (emp.nombre + ' ' + emp.apellido + ' (' + CAST(pe.anio AS VARCHAR) + '-T' + CAST(pe.trimestre AS VARCHAR) + ')') AS Info
                    FROM Evaluaciones e
                    INNER JOIN Empleados emp ON e.id_empleado = emp.id_empleado
                    INNER JOIN PeriodosEvaluacion pe ON e.id_periodo = pe.id_periodo
                    WHERE e.finalizada = 1 
                      AND e.EvaluadaSupervisor = 0 
                      {filtroDepartamento}
                    ORDER BY pe.anio DESC, pe.trimestre ASC";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    if (!(rol == "rh" || rol == "admin"))
                        cmd.Parameters.AddWithValue("@idSupervisor", idSupervisor);
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            lista.Add(new EvaluacionInfo
                            {
                                id_evaluacion = Convert.ToInt32(reader["id_evaluacion"]),
                                Info = reader["Info"].ToString()
                            });
                        }
                    }
                }
            }
            ddlEvaluaciones.DataSource = lista;
            ddlEvaluaciones.DataTextField = "Info";
            ddlEvaluaciones.DataValueField = "id_evaluacion";
            ddlEvaluaciones.DataBind();
            ddlEvaluaciones.Items.Insert(0, new ListItem("Selecciona evaluación", "0"));
        }

        protected void ddlEvaluaciones_SelectedIndexChanged(object sender, EventArgs e)
        {
            int idEval;
            if (int.TryParse(ddlEvaluaciones.SelectedValue, out idEval) && idEval != 0)
            {
                CargarDetalleEvaluacion(idEval);
            }
            else
            {
                pnlEvaluacion.Visible = false;
            }
        }

        private void CargarDetalleEvaluacion(int idEvaluacion)
        {
            DataTable dt = new DataTable();
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = @"
                    SELECT p.id_pregunta, p.texto_pregunta, 
                           ep.puntaje_empleado, ep.comentario_empleado,
                           ep.puntaje_supervisor, ep.comentario_supervisor
                    FROM EvaluacionesPreguntas ep
                    INNER JOIN Preguntas p ON ep.id_pregunta = p.id_pregunta
                    WHERE ep.id_evaluacion = @idEvaluacion";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@idEvaluacion", idEvaluacion);
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        dt.Load(reader);
                    }
                }
            }
            rptEvaluacion.DataSource = dt;
            rptEvaluacion.DataBind();
            pnlEvaluacion.Visible = true;
        }

        protected void btnGuardarEvaluacion_Click(object sender, EventArgs e)
        {
            int idEvaluacion = Convert.ToInt32(ddlEvaluaciones.SelectedValue);
            int idSupervisor = Convert.ToInt32(Session["id_empleado"]);
            string comentariosGenerales = txtComentariosGenerales.Text.Trim();

            //Validación: Revisar que el campo de comentarios generales no esté vacío
            if (string.IsNullOrWhiteSpace(comentariosGenerales))
            {
                litMensaje.Text = "<div class='alert alert-danger'>El campo de comentarios generales es obligatorio.</div>";
                return;
            }

            //Validación: Para cada pregunta, asegurarse de que se haya completado el comentario
            foreach (RepeaterItem item in rptEvaluacion.Items)
            {
                TextBox txtComentarioSupervisor = (TextBox)item.FindControl("txtComentarioSupervisor");
                if (txtComentarioSupervisor != null && string.IsNullOrWhiteSpace(txtComentarioSupervisor.Text))
                {
                    litMensaje.Text = "<div class='alert alert-danger'>Debe completar el comentario en cada pregunta de la evaluación.</div>";
                    return;
                }
            }

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                using (SqlTransaction tran = conn.BeginTransaction())
                {
                    try
                    {
                        //Actualizar cada respuesta en EvaluacionesPreguntas con puntaje y comentario del supervisor
                        foreach (RepeaterItem item in rptEvaluacion.Items)
                        {
                            HiddenField hfIdPregunta = (HiddenField)item.FindControl("hfIdPregunta");
                            DropDownList ddlPuntajeSupervisor = (DropDownList)item.FindControl("ddlPuntajeSupervisor");
                            TextBox txtComentarioSupervisor = (TextBox)item.FindControl("txtComentarioSupervisor");

                            int idPregunta = Convert.ToInt32(hfIdPregunta.Value);
                            int puntajeSupervisor = Convert.ToInt32(ddlPuntajeSupervisor.SelectedValue);
                            string comentarioSupervisor = txtComentarioSupervisor.Text.Trim();

                            string updateEP = @"
                                UPDATE EvaluacionesPreguntas
                                SET puntaje_supervisor = @puntaje_supervisor,
                                    comentario_supervisor = @comentario_supervisor
                                WHERE id_evaluacion = @idEvaluacion AND id_pregunta = @idPregunta";
                            using (SqlCommand cmd = new SqlCommand(updateEP, conn, tran))
                            {
                                cmd.Parameters.AddWithValue("@puntaje_supervisor", puntajeSupervisor);
                                cmd.Parameters.AddWithValue("@comentario_supervisor", comentarioSupervisor);
                                cmd.Parameters.AddWithValue("@idEvaluacion", idEvaluacion);
                                cmd.Parameters.AddWithValue("@idPregunta", idPregunta);
                                cmd.ExecuteNonQuery();
                            }
                        }

                        //Actualizar la Evaluación: asignar id_supervisor, comentarios generales y marcar EvaluadaSupervisor = 1
                        string updateEval = @"
                            UPDATE Evaluaciones
                            SET id_supervisor = @idSupervisor,
                                comentarios_supervisor = @comentarios_supervisor,
                                EvaluadaSupervisor = 1,
                                EvaluadoPor = @evaluadoPor
                            WHERE id_evaluacion = @idEvaluacion";
                        using (SqlCommand cmd = new SqlCommand(updateEval, conn, tran))
                        {
                            cmd.Parameters.AddWithValue("@idSupervisor", idSupervisor);
                            cmd.Parameters.AddWithValue("@comentarios_supervisor", comentariosGenerales);
                            cmd.Parameters.AddWithValue("@evaluadoPor", Session["username"].ToString());
                            cmd.Parameters.AddWithValue("@idEvaluacion", idEvaluacion);
                            cmd.ExecuteNonQuery();
                        }

                        //Actualizar resultado_promedio: almacenar la suma de puntajes supervisor para este periodo.
                        string updatePromedio = @"
                            UPDATE Evaluaciones
                            SET resultado_promedio = (
                                SELECT SUM(puntaje_supervisor)
                                FROM EvaluacionesPreguntas
                                WHERE id_evaluacion = @idEvaluacion
                            )
                            WHERE id_evaluacion = @idEvaluacion";
                        using (SqlCommand cmd = new SqlCommand(updatePromedio, conn, tran))
                        {
                            cmd.Parameters.AddWithValue("@idEvaluacion", idEvaluacion);
                            cmd.ExecuteNonQuery();
                        }

                        tran.Commit();
                        litMensaje.Text = "<div class='alert alert-success'>Evaluación guardada correctamente.</div>";
                        pnlEvaluacion.Visible = false;
                        CargarEvaluacionesPendientes(); //refrescar el listado

                        //Obtener el id del empleado evaluado
                        int idEmpleadoEvaluado = 0;
                        using (SqlConnection conn2 = new SqlConnection(connectionString))
                        {
                            conn2.Open();
                            string query = "SELECT id_empleado FROM Evaluaciones WHERE id_evaluacion = @idEvaluacion";
                            using (SqlCommand cmd = new SqlCommand(query, conn2))
                            {
                                cmd.Parameters.AddWithValue("@idEvaluacion", idEvaluacion);
                                object result = cmd.ExecuteScalar();
                                if (result != null && result != DBNull.Value)
                                {
                                    idEmpleadoEvaluado = Convert.ToInt32(result);
                                }
                            }
                        }
                        //Insertar la notificación para el empleado evaluado
                        if (idEmpleadoEvaluado > 0)
                        {
                            //Usamos el username del supervisor (actual) para el mensaje
                            string nombreSupervisor = Session["nombreCompleto"] != null ? Session["nombreCompleto"].ToString() : Session["username"].ToString();
                            string mensaje = $"Has sido evaluado por {nombreSupervisor}.";
                            //Definimos el tipo como "EvaluacionCompleta"
                            InsertarNotificacion(idEmpleadoEvaluado, mensaje, "EvaluacionCompleta");
                        }

                    }
                    catch (Exception ex)
                    {
                        tran.Rollback();
                        litMensaje.Text = "<div class='alert alert-danger'>Error al guardar: " + ex.Message + "</div>";
                    }
                }
            }
        }

        protected void btnCancelar_Click(object sender, EventArgs e)
        {
            //Limpiar controles de evaluación: reiniciar los dropdown y textboxes del repeater y comentarios generales
            foreach (RepeaterItem item in rptEvaluacion.Items)
            {
                DropDownList ddlPuntajeSupervisor = (DropDownList)item.FindControl("ddlPuntajeSupervisor");
                TextBox txtComentarioSupervisor = (TextBox)item.FindControl("txtComentarioSupervisor");
                if (ddlPuntajeSupervisor != null)
                    ddlPuntajeSupervisor.SelectedIndex = 0;
                if (txtComentarioSupervisor != null)
                    txtComentarioSupervisor.Text = "";
            }
            txtComentariosGenerales.Text = "";
        }

        protected void btnResetear_Click(object sender, EventArgs e)
        {
            int idEvaluacion;
            if (int.TryParse(ddlEvaluaciones.SelectedValue, out idEvaluacion) && idEvaluacion != 0)
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    //Eliminar las respuestas de EvaluacionesPreguntas para esa evaluación
                    string deleteEP = "DELETE FROM EvaluacionesPreguntas WHERE id_evaluacion = @idEvaluacion";
                    using (SqlCommand cmd = new SqlCommand(deleteEP, conn))
                    {
                        cmd.Parameters.AddWithValue("@idEvaluacion", idEvaluacion);
                        cmd.ExecuteNonQuery();
                    }
                    //RESET la evaluación: quitar id_supervisor, comentarios, resultado_promedio y EvaluadaSupervisor = 0
                    string resetEval = @"
                        UPDATE Evaluaciones 
                        SET finalizada = 0,
                            id_supervisor = NULL,
                            comentarios_supervisor = NULL,
                            resultado_promedio = NULL,
                            EvaluadaSupervisor = 0
                        WHERE id_evaluacion = @idEvaluacion";
                    using (SqlCommand cmd = new SqlCommand(resetEval, conn))
                    {
                        cmd.Parameters.AddWithValue("@idEvaluacion", idEvaluacion);
                        cmd.ExecuteNonQuery();
                    }
                    litMensaje.Text = "<div class='alert alert-success'>Evaluación eliminada correctamente.</div>";
                    CargarEvaluacionesPendientes();
                }
            }
            else
            {
                litMensaje.Text = "<div class='alert alert-warning'>Selecciona una evaluación para eliminar.</div>";
            }
        }

        private void InsertarNotificacion(int idEmpleado, string mensaje, string tipo)
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "INSERT INTO Notificaciones (id_empleado, mensaje, tipo, fecha_creacion, leido) " +
                               "VALUES (@id_empleado, @mensaje, @tipo, GETDATE(), 0)";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id_empleado", idEmpleado);
                    cmd.Parameters.AddWithValue("@mensaje", mensaje);
                    cmd.Parameters.AddWithValue("@tipo", tipo);
                    cmd.ExecuteNonQuery();
                }
            }
        }


    }
}

    
	
