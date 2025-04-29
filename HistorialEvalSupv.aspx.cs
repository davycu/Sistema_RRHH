using iTextSharp.text.pdf;
using iTextSharp.text;
using Sistema_RRHH.Clases;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Data;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Sistema_RRHH
{
	public partial class HistorialEvalSupv : System.Web.UI.Page
	{
        string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {

            Seguridad.VerificarSupervisor(this);

            if (!IsPostBack)
            {
                CargarAnios();
                CargarEmpleadosConEvaluaciones();
                //this.DataBind();
            }
        }

        private void CargarAnios()
        {
            List<int> anios = new List<int>();
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = @"SELECT DISTINCT pe.anio
                                 FROM PeriodosEvaluacion pe
                                 INNER JOIN Evaluaciones e ON pe.id_periodo = e.id_periodo
                                 WHERE e.finalizada = 1 AND e.EvaluadaSupervisor = 1
                                 ORDER BY pe.anio";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    using (SqlDataReader dr = cmd.ExecuteReader())
                    {
                        while (dr.Read())
                        {
                            anios.Add(Convert.ToInt32(dr["anio"]));
                        }
                    }
                }
            }
            ddlAnios.DataSource = anios;
            ddlAnios.DataBind();
            ddlAnios.Items.Insert(0, new System.Web.UI.WebControls.ListItem("Seleccione un año", "0"));
            ddlAnios.SelectedIndex = 0;
        }

        private void CargarEmpleadosConEvaluaciones()
        {
            //Solo se cargan los empleados del mismo departamento que el supervisor, excluyéndose a sí mismo.
            DataTable dt = new DataTable();
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                int idDepartamento = Convert.ToInt32(Session["id_departamento"]);
                int idSupervisor = Convert.ToInt32(Session["id_empleado"]);
                string query = @"
                    SELECT DISTINCT emp.id_empleado, (emp.nombre + ' ' + emp.apellido) AS nombreCompleto
                    FROM Evaluaciones e
                    INNER JOIN Empleados emp ON e.id_empleado = emp.id_empleado
                    WHERE e.finalizada = 1 AND e.EvaluadaSupervisor = 1
                      AND emp.id_departamento = @idDepartamento
                      AND emp.id_empleado <> @idSupervisor
                    ORDER BY nombreCompleto";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@idDepartamento", idDepartamento);
                    cmd.Parameters.AddWithValue("@idSupervisor", idSupervisor);
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        da.Fill(dt);
                    }
                }
            }
            ddlEmpleados.DataSource = dt;
            ddlEmpleados.DataTextField = "nombreCompleto";
            ddlEmpleados.DataValueField = "id_empleado";
            ddlEmpleados.DataBind();
            ddlEmpleados.Items.Insert(0, new System.Web.UI.WebControls.ListItem("Seleccione un empleado", "0"));
            ddlEmpleados.SelectedIndex = 0;
        }

        private void CargarTrimestresDisponibles(int anio, int idEmpleado)
        {
            List<int> trimestres = new List<int>();
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = @"
                    SELECT DISTINCT pe.trimestre
                    FROM PeriodosEvaluacion pe
                    INNER JOIN Evaluaciones e ON pe.id_periodo = e.id_periodo
                    WHERE pe.anio = @anio
                      AND e.id_empleado = @idEmpleado
                      AND e.finalizada = 1
                      AND e.EvaluadaSupervisor = 1
                    ORDER BY pe.trimestre";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@anio", anio);
                    cmd.Parameters.AddWithValue("@idEmpleado", idEmpleado);
                    using (SqlDataReader dr = cmd.ExecuteReader())
                    {
                        while (dr.Read())
                        {
                            trimestres.Add(Convert.ToInt32(dr["trimestre"]));
                        }
                    }
                }
            }
            ddlTrimestres.DataSource = trimestres;
            ddlTrimestres.DataBind();
            ddlTrimestres.Items.Insert(0, new System.Web.UI.WebControls.ListItem("Seleccione un trimestre", "0"));
            ddlTrimestres.SelectedIndex = 0;
        }

        protected void ddlAnios_SelectedIndexChanged(object sender, EventArgs e)
        {
            litAlert.Text = "";
            int anio, idEmpleado;
            if (int.TryParse(ddlAnios.SelectedValue, out anio) && int.TryParse(ddlEmpleados.SelectedValue, out idEmpleado))
            {
                if (anio != 0 && idEmpleado != 0)
                {
                    CargarTrimestresDisponibles(anio, idEmpleado);
                }
            }
            CargarHistorial();
        }

        protected void ddlEmpleados_SelectedIndexChanged(object sender, EventArgs e)
        {
            litAlert.Text = "";
            int anio, idEmpleado;
            if (int.TryParse(ddlAnios.SelectedValue, out anio) && int.TryParse(ddlEmpleados.SelectedValue, out idEmpleado))
            {
                if (anio != 0 && idEmpleado != 0)
                {
                    CargarTrimestresDisponibles(anio, idEmpleado);
                }
            }
            CargarHistorial();
        }

        protected void ddlTrimestres_SelectedIndexChanged(object sender, EventArgs e)
        {
            litAlert.Text = "";
            CargarHistorial();
        }

        private void CargarHistorial()
        {
            int anio, idEmpleado, trimestre;
            if (!int.TryParse(ddlAnios.SelectedValue, out anio) || anio == 0)
            {
                pnlHistorial.Visible = false;
                return;
            }
            if (!int.TryParse(ddlEmpleados.SelectedValue, out idEmpleado) || idEmpleado == 0)
            {
                pnlHistorial.Visible = false;
                return;
            }
            if (!int.TryParse(ddlTrimestres.SelectedValue, out trimestre) || trimestre == 0)
            {
                pnlHistorial.Visible = false;
                return;
            }

            DataTable dt = new DataTable();
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = @"
                    SELECT p.texto_pregunta, 
                           ep.puntaje_empleado, ep.comentario_empleado,
                           ep.puntaje_supervisor, ep.comentario_supervisor
                    FROM Evaluaciones e
                    INNER JOIN EvaluacionesPreguntas ep ON e.id_evaluacion = ep.id_evaluacion
                    INNER JOIN Preguntas p ON ep.id_pregunta = p.id_pregunta
                    INNER JOIN PeriodosEvaluacion pe ON e.id_periodo = pe.id_periodo
                    WHERE e.finalizada = 1 
                      AND e.EvaluadaSupervisor = 1
                      AND pe.anio = @anio
                      AND pe.trimestre = @trimestre
                      AND e.id_empleado = @idEmpleado";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@anio", anio);
                    cmd.Parameters.AddWithValue("@trimestre", trimestre);
                    cmd.Parameters.AddWithValue("@idEmpleado", idEmpleado);
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        da.Fill(dt);
                    }
                }
            }
            if (dt.Rows.Count > 0)
            {
                rptEvaluaciones.DataSource = dt;
                rptEvaluaciones.DataBind();
                pnlHistorial.Visible = true;
                litMensaje.Text = "";
                CargarDetallesEvaluacion(anio, idEmpleado, trimestre);
            }
            else
            {
                pnlHistorial.Visible = false;
                litMensaje.Text = "<div class='alert alert-info'>No se encontraron evaluaciones para los filtros seleccionados.</div>";
                litEvaluadoPor.Text = "";
                litFechaEvaluacion.Text = "";
                litDepartamento.Text = "";
            }
        }

        protected void lnkDescargarPdf_Click(object sender, EventArgs e)
        {
            litAlert.Text = "";

            int anio, idEmpleado, trimestre;
            if (!int.TryParse(ddlAnios.SelectedValue, out anio) ||
                !int.TryParse(ddlEmpleados.SelectedValue, out idEmpleado) ||
                !int.TryParse(ddlTrimestres.SelectedValue, out trimestre))
            {
                litAlert.Text = "<div class='alert alert-warning'>Debe elegir datos válidos para la descarga.</div>";
                return;
            }

            DataTable dt = ObtenerDatosReporte(anio, idEmpleado, trimestre);

            //Validación: si no hay datos, mostrar alerta y salir.
            if (dt.Rows.Count == 0)
            {
                litAlert.Text = "<div class='alert alert-warning'>Debe elegir datos para la descarga.</div>";
                return;
            }

            //Obtener detalles de la evaluación:
            string evaluadoPor = "N/A";
            string departamento = "N/A";
            string fechaEvaluacion = "N/A";
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = @"
            SELECT TOP 1 
                   e.EvaluadoPor, 
                   e.fecha_evaluacion, 
                   d.nombre AS Departamento
            FROM Evaluaciones e
            INNER JOIN Empleados emp ON e.id_empleado = emp.id_empleado
            INNER JOIN Departamentos d ON emp.id_departamento = d.id_departamento
            INNER JOIN PeriodosEvaluacion pe ON e.id_periodo = pe.id_periodo
            WHERE e.finalizada = 1 
              AND e.EvaluadaSupervisor = 1
              AND pe.anio = @anio
              AND pe.trimestre = @trimestre
              AND e.id_empleado = @idEmpleado";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@anio", anio);
                    cmd.Parameters.AddWithValue("@trimestre", trimestre);
                    cmd.Parameters.AddWithValue("@idEmpleado", idEmpleado);
                    using (SqlDataReader dr = cmd.ExecuteReader())
                    {
                        if (dr.Read())
                        {
                            evaluadoPor = dr["EvaluadoPor"] != DBNull.Value ? dr["EvaluadoPor"].ToString() : "N/A";
                            fechaEvaluacion = dr["fecha_evaluacion"] != DBNull.Value ? Convert.ToDateTime(dr["fecha_evaluacion"]).ToString("yyyy-MM-dd") : "N/A";
                            departamento = dr["Departamento"] != DBNull.Value ? dr["Departamento"].ToString() : "N/A";
                        }
                    }
                }
            }

            using (MemoryStream ms = new MemoryStream())
            {
                Document document = new Document(PageSize.A4, 25, 25, 30, 30);
                PdfWriter writer = PdfWriter.GetInstance(document, ms);
                document.Open();

                Paragraph titulo = new Paragraph("Historial de Evaluación", FontFactory.GetFont(FontFactory.HELVETICA_BOLD, 16));
                titulo.Alignment = Element.ALIGN_CENTER;
                document.Add(titulo);

                document.Add(new Paragraph(" "));
                document.Add(new Paragraph("Empleado: " + ddlEmpleados.SelectedItem.Text, FontFactory.GetFont(FontFactory.HELVETICA, 10)));
                document.Add(new Paragraph("Año: " + anio + "    Trimestre: " + trimestre, FontFactory.GetFont(FontFactory.HELVETICA, 10)));
                document.Add(new Paragraph(" "));
                //Agregar detalles adicionales:
                document.Add(new Paragraph("Evaluado Por: " + evaluadoPor, FontFactory.GetFont(FontFactory.HELVETICA, 10)));
                document.Add(new Paragraph("Departamento: " + departamento, FontFactory.GetFont(FontFactory.HELVETICA, 10)));
                document.Add(new Paragraph("Fecha Evaluación: " + fechaEvaluacion, FontFactory.GetFont(FontFactory.HELVETICA, 10)));
                document.Add(new Paragraph(" "));

                PdfPTable pdfTable = new PdfPTable(dt.Columns.Count);
                pdfTable.WidthPercentage = 100;
                foreach (DataColumn column in dt.Columns)
                {
                    PdfPCell cell = new PdfPCell(new Phrase(column.ColumnName, FontFactory.GetFont(FontFactory.HELVETICA_BOLD, 10)));
                    cell.BackgroundColor = new BaseColor(230, 230, 230);
                    pdfTable.AddCell(cell);
                }
                foreach (DataRow row in dt.Rows)
                {
                    foreach (var cellData in row.ItemArray)
                    {
                        pdfTable.AddCell(new Phrase(cellData.ToString(), FontFactory.GetFont(FontFactory.HELVETICA, 10)));
                    }
                }
                document.Add(pdfTable);
                document.Close();
                writer.Close();

                byte[] bytes = ms.ToArray();
                Response.ContentType = "application/pdf";
                Response.AddHeader("Content-Disposition", "attachment; filename=HistorialEvaluacion.pdf");
                Response.Cache.SetCacheability(HttpCacheability.NoCache);
                Response.BinaryWrite(bytes);
                Response.End();
            }
        }

        private DataTable ObtenerDatosReporte(int anio, int idEmpleado, int trimestre)
        {
            DataTable dt = new DataTable();
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = @"
                    SELECT p.texto_pregunta, 
                           ep.puntaje_empleado, ep.comentario_empleado,
                           ep.puntaje_supervisor, ep.comentario_supervisor
                    FROM Evaluaciones e
                    INNER JOIN EvaluacionesPreguntas ep ON e.id_evaluacion = ep.id_evaluacion
                    INNER JOIN Preguntas p ON ep.id_pregunta = p.id_pregunta
                    INNER JOIN PeriodosEvaluacion pe ON e.id_periodo = pe.id_periodo
                    WHERE e.finalizada = 1 
                      AND e.EvaluadaSupervisor = 1
                      AND pe.anio = @anio
                      AND pe.trimestre = @trimestre
                      AND e.id_empleado = @idEmpleado";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@anio", anio);
                    cmd.Parameters.AddWithValue("@trimestre", trimestre);
                    cmd.Parameters.AddWithValue("@idEmpleado", idEmpleado);
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        da.Fill(dt);
                    }
                }
            }
            return dt;
        }

        private void CargarDetallesEvaluacion(int anio, int idEmpleado, int trimestre)
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = @"
            SELECT TOP 1 
                   e.EvaluadoPor, 
                   e.fecha_evaluacion, 
                   d.nombre AS Departamento
            FROM Evaluaciones e
            INNER JOIN Empleados emp ON e.id_empleado = emp.id_empleado
            INNER JOIN Departamentos d ON emp.id_departamento = d.id_departamento
            INNER JOIN PeriodosEvaluacion pe ON e.id_periodo = pe.id_periodo
            WHERE e.finalizada = 1 
              AND e.EvaluadaSupervisor = 1
              AND pe.anio = @anio
              AND pe.trimestre = @trimestre
              AND e.id_empleado = @idEmpleado";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@anio", anio);
                    cmd.Parameters.AddWithValue("@trimestre", trimestre);
                    cmd.Parameters.AddWithValue("@idEmpleado", idEmpleado);
                    using (SqlDataReader dr = cmd.ExecuteReader())
                    {
                        if (dr.Read())
                        {
                            litEvaluadoPor.Text = dr["EvaluadoPor"] != DBNull.Value ? dr["EvaluadoPor"].ToString() : "N/A";
                            litFechaEvaluacion.Text = dr["fecha_evaluacion"] != DBNull.Value ? Convert.ToDateTime(dr["fecha_evaluacion"]).ToString("yyyy-MM-dd") : "N/A";
                            litDepartamento.Text = dr["Departamento"] != DBNull.Value ? dr["Departamento"].ToString() : "N/A";
                        }
                        else
                        {
                            litEvaluadoPor.Text = "N/A";
                            litFechaEvaluacion.Text = "N/A";
                            litDepartamento.Text = "N/A";
                        }
                    }
                }
            }
        }

        protected void btnNuevaBusqueda_Click(object sender, EventArgs e)
        {
            //Reiniciar los dropdowns
            ddlAnios.ClearSelection();
            ddlAnios.SelectedIndex = 0;

            ddlEmpleados.ClearSelection();
            ddlEmpleados.SelectedIndex = 0;

            ddlTrimestres.ClearSelection();
            ddlTrimestres.SelectedIndex = 0;

            //Limpiar el contenido del panel de historial y detalles
            pnlHistorial.Visible = false;
            litMensaje.Text = "";
            rptEvaluaciones.DataSource = null;
            rptEvaluaciones.DataBind();

            litEvaluadoPor.Text = "";
            litDepartamento.Text = "";
            litFechaEvaluacion.Text = "";

            litMensaje.Text = "";

            //Limpiar el repeater
            rptEvaluaciones.DataSource = null;
            rptEvaluaciones.DataBind();
        }

    }
}