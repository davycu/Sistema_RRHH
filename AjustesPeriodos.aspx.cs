using Sistema_RRHH.Clases;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Sistema_RRHH
{
    public partial class AjustesPeriodos : System.Web.UI.Page
    {
        string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;
        protected void Page_Load(object sender, EventArgs e)
        {

            if (Session["username"] == null)
            {
                Response.Redirect("Login.aspx");
            }

            Seguridad.VerificarAdmin(this);

            if (!IsPostBack)
            {
                CargarPeriodos();
            }
        }

        protected void btnCrearPeriodo_Click(object sender, EventArgs e)
        {

            litMensaje.Text = "";

            int anio;
            int trimestre;
            DateTime fechaInicio;
            DateTime fechaFin;

            if (!int.TryParse(ddlAnio.SelectedValue, out anio))
            {
                litMensaje.Text = "<div class='alert alert-danger'>Ingrese un año válido.</div>";
                return;
            }
            if (!int.TryParse(ddlTrimestre.SelectedValue, out trimestre))
            {
                litMensaje.Text = "<div class='alert alert-danger'>Seleccione un trimestre válido.</div>";
                return;
            }
            if (!DateTime.TryParse(txtFechaInicio.Text.Trim(), out fechaInicio))
            {
                litMensaje.Text = "<div class='alert alert-danger'>Ingrese una fecha de inicio válida.</div>";
                return;
            }
            if (!DateTime.TryParse(txtFechaFin.Text.Trim(), out fechaFin))
            {
                litMensaje.Text = "<div class='alert alert-danger'>Ingrese una fecha de fin válida.</div>";
                return;
            }
            if (fechaFin <= fechaInicio)
            {
                litMensaje.Text = "<div class='alert alert-danger'>La fecha de fin no puede ser anterior a la fecha de inicio.</div>";
                return;
            }

            //si se está editando (hay un valor en hfPeriodoID), actualizar el registro o se crea uno nuevo.
            if (!string.IsNullOrEmpty(hfPeriodoID.Value))
            {
                int idPeriodo = Convert.ToInt32(hfPeriodoID.Value);
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    string update = "UPDATE PeriodosEvaluacion SET anio = @anio, trimestre = @trimestre, fecha_inicio = @fechaInicio, fecha_fin = @fechaFin WHERE id_periodo = @idPeriodo";
                    using (SqlCommand cmd = new SqlCommand(update, conn))
                    {
                        cmd.Parameters.AddWithValue("@anio", anio);
                        cmd.Parameters.AddWithValue("@trimestre", trimestre);
                        cmd.Parameters.AddWithValue("@fechaInicio", fechaInicio);
                        cmd.Parameters.AddWithValue("@fechaFin", fechaFin);
                        cmd.Parameters.AddWithValue("@idPeriodo", idPeriodo);
                        int result = cmd.ExecuteNonQuery();
                        if (result > 0)
                        {
                            litMensaje.Text = "<div class='alert alert-success'>Periodo actualizado exitosamente.</div>";
                        }
                        else
                        {
                            litMensaje.Text = "<div class='alert alert-danger'>Error al actualizar el periodo.</div>";
                        }
                    }
                }
            }
            else
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    string query = "INSERT INTO PeriodosEvaluacion (anio, trimestre, fecha_inicio, fecha_fin) VALUES (@anio, @trimestre, @fechaInicio, @fechaFin)";
                    using (SqlCommand cmd = new SqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("@anio", anio);
                        cmd.Parameters.AddWithValue("@trimestre", trimestre);
                        cmd.Parameters.AddWithValue("@fechaInicio", fechaInicio);
                        cmd.Parameters.AddWithValue("@fechaFin", fechaFin);
                        int result = cmd.ExecuteNonQuery();
                        if (result > 0)
                        {
                            litMensaje.Text = "<div class='alert alert-success'>Periodo creado exitosamente.</div>";
                        }
                        else
                        {
                            litMensaje.Text = "<div class='alert alert-danger'>Error al crear el periodo.</div>";
                        }
                    }
                }
            }
            LimpiarFormulario();
            CargarPeriodos();
        }

        private void CargarPeriodos()
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "SELECT id_periodo, anio, trimestre, fecha_inicio, fecha_fin FROM PeriodosEvaluacion ORDER BY anio DESC, trimestre ASC";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    SqlDataReader reader = cmd.ExecuteReader();
                    repeaterPeriodos.DataSource = reader;
                    repeaterPeriodos.DataBind();
                }
            }
        }

        protected void lnkEliminarPeriodo_Click(object sender, EventArgs e)
        {
            litMensaje.Text = "";

            LinkButton lnk = (LinkButton)sender;
            int idPeriodo = Convert.ToInt32(lnk.CommandArgument);
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "DELETE FROM PeriodosEvaluacion WHERE id_periodo = @idPeriodo";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@idPeriodo", idPeriodo);
                    cmd.ExecuteNonQuery();
                }   
            }
            litMensaje.Text = "<div class='alert alert-danger'>Periodo eliminado correctamente.</div>";
            CargarPeriodos();
        }

        protected void lnkEditarPeriodo_Click(object sender, EventArgs e)
        {
            litMensaje.Text = "";
            //Cargar el periodo en el formulario para editar
            LinkButton lnk = (LinkButton)sender;
            int idPeriodo = Convert.ToInt32(lnk.CommandArgument);
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "SELECT anio, trimestre, fecha_inicio, fecha_fin FROM PeriodosEvaluacion WHERE id_periodo = @idPeriodo";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@idPeriodo", idPeriodo);
                    SqlDataReader reader = cmd.ExecuteReader();
                    if (reader.Read())
                    {
                        ddlAnio.SelectedValue = reader["anio"].ToString();
                        ddlTrimestre.SelectedValue = reader["trimestre"].ToString();
                        txtFechaInicio.Text = Convert.ToDateTime(reader["fecha_inicio"]).ToString("yyyy-MM-dd");
                        txtFechaFin.Text = Convert.ToDateTime(reader["fecha_fin"]).ToString("yyyy-MM-dd");
                        hfPeriodoID.Value = idPeriodo.ToString();
                        // Cambiar el texto del título o botón para indicar que se está editando
                        btnCrearPeriodo.Text = "Guardar Cambios";
                        //formTitle.InnerText = "Editar Periodo";
                    }
                    reader.Close();
                }
            }
        }

        protected void btnCancelar_Click(object sender, EventArgs e)
        {
            LimpiarFormulario();
        }

        private void LimpiarFormulario()
        {
            ddlAnio.SelectedIndex = 0;
            ddlTrimestre.SelectedIndex = 0;
            txtFechaInicio.Text = "";
            txtFechaFin.Text = "";
            hfPeriodoID.Value = "";
            btnCrearPeriodo.Text = "Crear Periodo";
        }

    }
}
	
