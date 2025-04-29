using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Drawing.Printing;
using System.IO;
using System.Xml.Linq;
using iTextSharp.text;
using iTextSharp.text.pdf;
using iTextSharp.tool.xml;
using Sistema_RRHH.Clases;

namespace Sistema_RRHH
{
    public partial class ReporteEvaluacionAnual : System.Web.UI.Page
    {
        string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {

            Seguridad.VerificarAdminRh(this);

            if (!IsPostBack)
            {
                //primero cargamos los años disponibles en el dropdown
                CargarAnios();
                //luego generamos el reporte utilizando el año seleccionado (o el año actual por defecto)
                CargarReporte();
                CargarResumenPendientes();
            }
        }

        private void CargarAnios()
        {
            //se crea un DataTable para almacenar los años obtenidos desde la tabla PeriodosEvaluacion
            DataTable dtAnios = new DataTable();
            dtAnios.Columns.Add("anio", typeof(int));

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "SELECT DISTINCT anio FROM PeriodosEvaluacion ORDER BY anio ASC";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            int anio = Convert.ToInt32(reader["anio"]);
                            dtAnios.Rows.Add(anio);
                        }
                    }
                }
            }
            ddlAnioReporte.DataSource = dtAnios;
            ddlAnioReporte.DataTextField = "anio";
            ddlAnioReporte.DataValueField = "anio";
            ddlAnioReporte.DataBind();
        }

        protected void ddlAnioReporte_SelectedIndexChanged(object sender, EventArgs e)
        {
            CargarReporte();
        }

        private void CargarReporte()
        {
            //se definen las columnas del DataTable que alimentará el GridView.
            DataTable dtReporte = new DataTable();
            dtReporte.Columns.Add("codigo_empleado", typeof(string));
            dtReporte.Columns.Add("nombreEmpleado", typeof(string));
            dtReporte.Columns.Add("departamento", typeof(string));
            dtReporte.Columns.Add("fechaIngreso", typeof(DateTime));
            dtReporte.Columns.Add("totalPuntos", typeof(int));
            dtReporte.Columns.Add("porcentajeAnual", typeof(decimal));
            dtReporte.Columns.Add("salario", typeof(decimal));
            dtReporte.Columns.Add("porcentajeAumento", typeof(decimal));
            dtReporte.Columns.Add("nuevoSalario", typeof(decimal));
            dtReporte.Columns.Add("evaluacionesSupervisor", typeof(string));
            dtReporte.Columns.Add("evaluacionesSupervisorPendientes", typeof(string));
            dtReporte.Columns.Add("evaluacionesAutoPendientes", typeof(string));

            int anio = !string.IsNullOrEmpty(ddlAnioReporte.SelectedValue)
                ? Convert.ToInt32(ddlAnioReporte.SelectedValue)
                : DateTime.Now.Year;

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                //se filtran sólo los empleados activos (activo = 1)
                string query = @"
                    SELECT e.id_empleado, e.codigo_empleado, e.nombre, e.apellido, e.salario, e.id_departamento, e.fecha_ingreso 
                    FROM Empleados e
                    INNER JOIN Usuarios u ON e.id_usuario = u.id_usuario
                    WHERE u.estado = 'activo'";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            int idEmpleado = Convert.ToInt32(reader["id_empleado"]);
                            string codigoEmpleado = reader["codigo_empleado"].ToString();
                            string nombreEmpleado = reader["nombre"].ToString() + " " + reader["apellido"].ToString();
                            decimal salario = Convert.ToDecimal(reader["salario"]);
                            int idDepartamento = Convert.ToInt32(reader["id_departamento"]);
                            DateTime fechaIngreso = Convert.ToDateTime(reader["fecha_ingreso"]);

                            //llamada al procedimiento almacenado para obtener datos de autoevaluación.
                            int totalPuntos = 0;
                            decimal porcentajeAnual = 0;
                            using (SqlConnection connProc = new SqlConnection(connectionString))
                            {
                                connProc.Open();
                                using (SqlCommand cmdProc = new SqlCommand("CalcularPromedioAnual", connProc))
                                {
                                    cmdProc.CommandType = CommandType.StoredProcedure;
                                    cmdProc.Parameters.AddWithValue("@idEmpleado", idEmpleado);
                                    cmdProc.Parameters.AddWithValue("@anio", anio);

                                    using (SqlDataReader procReader = cmdProc.ExecuteReader())
                                    {
                                        if (procReader.Read())
                                        {
                                            totalPuntos = procReader["TotalPuntos"] != DBNull.Value ? Convert.ToInt32(procReader["TotalPuntos"]) : 0;
                                            porcentajeAnual = procReader["PorcentajeAnual"] != DBNull.Value ? Convert.ToDecimal(procReader["PorcentajeAnual"]) : 0;
                                        }
                                    }
                                }
                            }

                            //si no existe al menos una autoevaluación (totalPuntos es 0), no se muestra al empleado.
                            if (totalPuntos == 0)
                                continue;

                            //definir el porcentaje de aumento según el desempeño.
                            decimal porcentajeAumento = 0;
                            if (porcentajeAnual >= 90)
                                porcentajeAumento = 5;
                            else if (porcentajeAnual >= 80)
                                porcentajeAumento = 4;
                            else if (porcentajeAnual >= 70)
                                porcentajeAumento = 3;
                            else if (porcentajeAnual >= 60)
                                porcentajeAumento = 2;
                            else
                                porcentajeAumento = 1;

                            decimal nuevoSalario = salario + (salario * porcentajeAumento / 100);
                            string departamento = ObtenerNombreDepartamento(idDepartamento);

                            //obtener períodos ya evaluados por supervisor.
                            string evaluacionesSupervisor = ObtenerPeriodosSupervisor(idEmpleado, anio);
                            //Obtener períodos pendientes por evaluación del supervisor.
                            string evaluacionesSupervisorPendientes = ObtenerPeriodosSupervisorPendientes(idEmpleado, anio);
                            //obtener períodos pendientes de autoevaluación (solo para períodos posteriores a la fecha de ingreso).
                            string evaluacionesAutoPendientes = ObtenerPeriodosAutoevaluacionPendientes(idEmpleado, anio, fechaIngreso);

                            dtReporte.Rows.Add(codigoEmpleado, nombreEmpleado, departamento, fechaIngreso, totalPuntos, porcentajeAnual, salario, porcentajeAumento, nuevoSalario, evaluacionesSupervisor, evaluacionesSupervisorPendientes, evaluacionesAutoPendientes);
                        }
                    }
                }
            }

            gvReporte.DataSource = dtReporte;
            gvReporte.DataBind();
        }

        private string ObtenerNombreDepartamento(int idDepartamento)
        {
            string nombreDepto = "";
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "SELECT nombre FROM Departamentos WHERE id_departamento = @id_departamento";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id_departamento", idDepartamento);
                    object result = cmd.ExecuteScalar();
                    if (result != null && result != DBNull.Value)
                        nombreDepto = result.ToString();
                }
            }
            return nombreDepto;
        }

        private string ObtenerPeriodosSupervisor(int idEmpleado, int anio)
        {
            string periodos = "";
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                //se obtienen los períodos en los que la autoevaluación fue completada y el supervisor ya evaluó (EvaluadaSupervisor = 1)
                string query = @"
            SELECT pe.trimestre, pe.anio 
            FROM Evaluaciones e
            INNER JOIN PeriodosEvaluacion pe ON e.id_periodo = pe.id_periodo
            WHERE e.id_empleado = @idEmpleado
              AND pe.anio = @anio
              AND e.finalizada = 1
              AND e.EvaluadaSupervisor = 1";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@idEmpleado", idEmpleado);
                    cmd.Parameters.AddWithValue("@anio", anio);
                    using (SqlDataReader dr = cmd.ExecuteReader())
                    {
                        List<string> listaPeriodos = new List<string>();
                        while (dr.Read())
                        {
                            int trimestre = Convert.ToInt32(dr["trimestre"]);
                            int anioEvaluacion = Convert.ToInt32(dr["anio"]);
                            listaPeriodos.Add(anioEvaluacion + " Q" + trimestre);
                        }
                        periodos = string.Join("<br />", listaPeriodos);
                    }
                }
            }
            return periodos;
        }

        private string ObtenerPeriodosSupervisorPendientes(int idEmpleado, int anio)
        {
            string periodos = "";
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                //se obtienen los períodos en los que el empleado completó su autoevaluación (finalizada = 1)
                // pero el supervisor aún no evaluó (EvaluadaSupervisor = 0)
                string query = @"
            SELECT pe.trimestre, pe.anio 
            FROM Evaluaciones e
            INNER JOIN PeriodosEvaluacion pe ON e.id_periodo = pe.id_periodo
            WHERE e.id_empleado = @idEmpleado
              AND pe.anio = @anio
              AND e.finalizada = 1
              AND e.EvaluadaSupervisor = 0";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@idEmpleado", idEmpleado);
                    cmd.Parameters.AddWithValue("@anio", anio);
                    using (SqlDataReader dr = cmd.ExecuteReader())
                    {
                        List<string> listaPeriodos = new List<string>();
                        while (dr.Read())
                        {
                            int trimestre = Convert.ToInt32(dr["trimestre"]);
                            int anioEvaluacion = Convert.ToInt32(dr["anio"]);
                            listaPeriodos.Add(anioEvaluacion + " Q" + trimestre);
                        }
                        periodos = string.Join("<br />", listaPeriodos);
                    }
                }
            }
            return periodos;
        }

        private string ObtenerPeriodosAutoevaluacionPendientes(int idEmpleado, int anio, DateTime fechaIngreso)
        {
            string periodos = "";
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                //Se obtienen los períodos del año cuyo inicio es posterior o igual a la fecha de ingreso
                // y para los cuales no existe ningún registro de autoevaluación completada (finalizada = 1)
                string query = @"
            SELECT pe.trimestre, pe.anio, pe.fecha_inicio
            FROM PeriodosEvaluacion pe
            WHERE pe.anio = @anio 
              AND pe.fecha_inicio >= @fechaIngreso
              AND NOT EXISTS (
                    SELECT 1 
                    FROM Evaluaciones e 
                    WHERE e.id_periodo = pe.id_periodo 
                      AND e.id_empleado = @idEmpleado 
                      AND e.finalizada = 1
              )";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@idEmpleado", idEmpleado);
                    cmd.Parameters.AddWithValue("@anio", anio);
                    cmd.Parameters.AddWithValue("@fechaIngreso", fechaIngreso);
                    using (SqlDataReader dr = cmd.ExecuteReader())
                    {
                        List<string> listaPeriodos = new List<string>();
                        while (dr.Read())
                        {
                            int trimestre = Convert.ToInt32(dr["trimestre"]);
                            int anioEvaluacion = Convert.ToInt32(dr["anio"]);
                            listaPeriodos.Add(anioEvaluacion + " Q" + trimestre);
                        }
                        periodos = string.Join("<br />", listaPeriodos);
                    }
                }
            }
            return periodos;
        }

        protected void btnExportarExcel_Click(object sender, EventArgs e)
        {
            Response.Clear();
            Response.AddHeader("content-disposition", "attachment;filename=ReporteEvaluacionAnual.xls");
            Response.ContentType = "application/vnd.ms-excel";
            StringWriter sw = new StringWriter();
            HtmlTextWriter hw = new HtmlTextWriter(sw);
            gvReporte.RenderControl(hw);
            Response.Write(sw.ToString());
            Response.End();
        }

        protected void btnExportarPDF_Click(object sender, EventArgs e)
        {
            // Desactivar la paginación para exportar todo el contenido.
            gvReporte.AllowPaging = false;
            CargarReporte(); //Aseguramos que el GridView esté actualizado.

            //Renderizar el GridView a HTML.
            StringWriter sw = new StringWriter();
            HtmlTextWriter hw = new HtmlTextWriter(sw);
            gvReporte.RenderControl(hw);
            string gridHTML = sw.ToString();

            //Crear un StringReader para usar con XMLWorkerHelper.
            StringReader sr = new StringReader(gridHTML);

            //Configurar el documento PDF en orientación horizontal (landscape).
            Document pdfDoc = new Document(PageSize.A4.Rotate(), 10f, 10f, 20f, 10f);
            PdfWriter writer = PdfWriter.GetInstance(pdfDoc, Response.OutputStream);
            pdfDoc.Open();

            //Agregar un título centrado.
            string anio = ddlAnioReporte.SelectedValue;
            Paragraph title = new Paragraph("Reporte Evaluación para el año " + anio, FontFactory.GetFont(FontFactory.HELVETICA_BOLD, 16));
            title.Alignment = Element.ALIGN_CENTER;
            pdfDoc.Add(title);
            pdfDoc.Add(new Paragraph("\n"));

            //Procesar el HTML del GridView.
            XMLWorkerHelper.GetInstance().ParseXHtml(writer, pdfDoc, sr);
            pdfDoc.Close();

            Response.ContentType = "application/pdf";
            Response.AddHeader("content-disposition", "attachment;filename=ReporteEvaluacionAnual.pdf");
            Response.Cache.SetCacheability(HttpCacheability.NoCache);
            Response.Write(pdfDoc);
            Response.End();
        }
        

        //sobrescribir este método para exportar correctamente el GridView.
        public override void VerifyRenderingInServerForm(Control control)
        {
            //No seimplementa
        }

        private DataTable ObtenerEmpleadosPendientes()
        {
            DataTable dt = new DataTable();
            dt.Columns.Add("Empleado", typeof(string));
            dt.Columns.Add("PendienteAnios", typeof(string));
            dt.Columns.Add("Departamento", typeof(string));
            dt.Columns.Add("Cargo", typeof(string));

            string query = @"
                        SELECT 
                          e.id_empleado,
                          (e.nombre + ' ' + e.apellido) AS Empleado,
                          d.nombre AS Departamento,
                          e.cargo AS Cargo,
                          STUFF((
                              SELECT ', ' + CAST(pe.anio AS VARCHAR(4))
                              FROM PeriodosEvaluacion pe
                              WHERE pe.fecha_inicio >= e.fecha_ingreso
                                AND NOT EXISTS (
                                     SELECT 1 
                                     FROM Evaluaciones ev 
                                     WHERE ev.id_empleado = e.id_empleado 
                                       AND ev.id_periodo = pe.id_periodo 
                                       AND ev.finalizada = 1
                                )
                              GROUP BY pe.anio
                              FOR XML PATH(''), TYPE
                          ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS PendienteAnios
                        FROM Empleados e
                        INNER JOIN Usuarios u ON e.id_usuario = u.id_usuario
                        INNER JOIN Departamentos d ON e.id_departamento = d.id_departamento
                        WHERE u.estado = 'activo'
                          AND NOT EXISTS (
                              SELECT 1 
                              FROM Evaluaciones ev2 
                              WHERE ev2.id_empleado = e.id_empleado 
                                AND ev2.finalizada = 1
                          )
                          AND NOT (e.id_supervisor_departamento IS NOT NULL AND d.nombre = 'Recursos Humanos')
";

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    conn.Open();
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        da.Fill(dt);
                    }
                }
            }
            return dt;
        }

        //metodo para cargar el GridView de resumen de pendientes.
        private void CargarResumenPendientes()
        {
            DataTable dtResumen = ObtenerEmpleadosPendientes();
            gvResumenPendientes.DataSource = dtResumen;
            gvResumenPendientes.DataBind();
        }

    }
}
