using Sistema_RRHH.Clases;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Sistema_RRHH
{
    public partial class IngresarPermiso : System.Web.UI.Page
    {
        string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;
        protected void Page_Load(object sender, EventArgs e)
        {

            //Verificar que el usuario esté autenticado
            if (Session["username"] == null)
            {
                Response.Redirect("Login.aspx");
            }
            if (!IsPostBack)
            {
                CargarTiposPermisos();
                ActualizarSaldo();
                CargarPermisosPendientes();
            }
        }


        //carga los tipos de permisos en el dropdown.
        private void CargarTiposPermisos()
        {
            litAlert.Text = "";
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "SELECT id_tipo_permiso, nombre_permiso FROM TiposPermisos ORDER BY nombre_permiso";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    ddlTipoPermiso.DataSource = cmd.ExecuteReader();
                    ddlTipoPermiso.DataValueField = "id_tipo_permiso";
                    ddlTipoPermiso.DataTextField = "nombre_permiso";
                    ddlTipoPermiso.DataBind();
                    ddlTipoPermiso.Items.Insert(0, new System.Web.UI.WebControls.ListItem("Seleccione un tipo de permiso", "0"));
                }
            }
        }

        protected void ddlTipoPermiso_SelectedIndexChanged(object sender, EventArgs e)
        {
            litAlert.Text = "";
            ActualizarSaldo();
        }


        //actualiza y muestra el saldo disponible para el tipo seleccionado.
        //si no hay registro en SaldoPermisos, se usa el valor de TiposPermisos.
        private void ActualizarSaldo()
        {
            lblSaldo.Text = "";
            if (Session["id_empleado"] != null && ddlTipoPermiso.SelectedValue != "0")
            {
                int idEmpleado = Convert.ToInt32(Session["id_empleado"]);
                int idTipoPermiso = Convert.ToInt32(ddlTipoPermiso.SelectedValue);
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    string query = "SELECT horas_disponibles FROM SaldoPermisos " +
                                   "WHERE id_empleado = @id_empleado AND id_tipo_permiso = @id_tipo_permiso";
                    using (SqlCommand cmd = new SqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("@id_empleado", idEmpleado);
                        cmd.Parameters.AddWithValue("@id_tipo_permiso", idTipoPermiso);
                        object result = cmd.ExecuteScalar();
                        double horas = 0;
                        if (result != null && result != DBNull.Value)
                        {
                            horas = Convert.ToDouble(result);
                        }
                        else
                        {
                            //Si no hay registro, obtenemos el saldo inicial de TiposPermisos
                            string queryTipo = "SELECT dias_maximos_anuales FROM TiposPermisos WHERE id_tipo_permiso = @id_tipo_permiso";
                            using (SqlCommand cmdTipo = new SqlCommand(queryTipo, conn))
                            {
                                cmdTipo.Parameters.AddWithValue("@id_tipo_permiso", idTipoPermiso);
                                object resultTipo = cmdTipo.ExecuteScalar();
                                if (resultTipo != null && resultTipo != DBNull.Value)
                                {
                                    int diasInicial = Convert.ToInt32(resultTipo);
                                    horas = diasInicial * 8.0;
                                }
                            }
                        }
                        double diasDecimal = horas / 8.0;
                        lblSaldo.Text = "<div style='font-size:1.25rem; font-weight:bold; text-align:left; " +
                                        "background-color:#e0f7fa; padding:10px; border-radius:5px; margin-bottom:10px;'>" +
                                        "Disponible: <strong>Días:</strong> " + diasDecimal.ToString("0.##") +
                                        " | <strong>Horas:</strong> " + horas.ToString("0.##") +
                                        "</div>";
                    }
                }
            }
            else
            {
                lblSaldo.Text = "";
            }
        }


        //Procesa la solicitud del permiso.
        protected void btnSolicitar_Click(object sender, EventArgs e)
        {
            litAlert.Text = "";

            //Validar que se haya seleccionado un tipo de permiso
            if (ddlTipoPermiso.SelectedValue == "0")
            {
                litAlert.Text = "<div class='alert alert-danger'>Seleccione un tipo de permiso.</div>";
                return;
            }

            if (Session["id_empleado"] == null)
            {
                litAlert.Text = "<div class='alert alert-danger'>No se encontró el empleado logueado.</div>";
                return;
            }
            //validar justificacion
            if (string.IsNullOrWhiteSpace(txtComentarios.Text))
            {
                litAlert.Text = "<div class='alert alert-danger'>La justificación es obligatoria.</div>";
                return;
            }

            int idEmpleado = Convert.ToInt32(Session["id_empleado"]);
            int idTipoPermiso = Convert.ToInt32(ddlTipoPermiso.SelectedValue);

            //Antes de continuar, verificar el saldo disponible
            double horasDisponibles = 0;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string querySaldo = "SELECT horas_disponibles FROM SaldoPermisos WHERE id_empleado = @id_empleado AND id_tipo_permiso = @id_tipo_permiso";
                using (SqlCommand cmdSaldo = new SqlCommand(querySaldo, conn))
                {
                    cmdSaldo.Parameters.AddWithValue("@id_empleado", idEmpleado);
                    cmdSaldo.Parameters.AddWithValue("@id_tipo_permiso", idTipoPermiso);
                    object resultSaldo = cmdSaldo.ExecuteScalar();
                    if (resultSaldo != null && resultSaldo != DBNull.Value)
                    {
                        horasDisponibles = Convert.ToDouble(resultSaldo);
                    }
                    else
                    {
                        //No existe registro: obtener saldo inicial de TiposPermisos
                        string queryTipo = "SELECT dias_maximos_anuales FROM TiposPermisos WHERE id_tipo_permiso = @id_tipo_permiso";
                        using (SqlCommand cmdTipo = new SqlCommand(queryTipo, conn))
                        {
                            cmdTipo.Parameters.AddWithValue("@id_tipo_permiso", idTipoPermiso);
                            object resultTipo = cmdTipo.ExecuteScalar();
                            if (resultTipo != null && resultTipo != DBNull.Value)
                            {
                                int diasInicial = Convert.ToInt32(resultTipo);
                                horasDisponibles = diasInicial * 8.0;
                            }
                        }
                    }
                }
            }
            if (horasDisponibles <= 0)
            {
                litAlert.Text = "<div class='alert alert-danger'>No tiene saldo disponible para solicitar este permiso.</div>";
                return;
            }

            // Procesar fechas y horas solicitadas
            DateTime fechaInicio;
            if (!DateTime.TryParse(txtFechaInicio.Text.Trim(), out fechaInicio))
            {
                litAlert.Text = "<div class='alert alert-danger'>Ingrese una fecha de inicio válida.</div>";
                return;
            }

            DateTime fechaFin;
            int horasSolicitadas = 0;

            // Caso: "1 Día"
            if (rbUnDia.Checked)
            {
                fechaFin = fechaInicio;
                horasSolicitadas = 8;
            }
            else if (!string.IsNullOrWhiteSpace(txtFechaFin.Text.Trim()))
            {
                if (!DateTime.TryParse(txtFechaFin.Text.Trim(), out fechaFin))
                {
                    litAlert.Text = "<div class='alert alert-danger'>Ingrese una fecha de fin válida.</div>";
                    return;
                }
                //Validación: Fecha de fin no debe ser anterior a la de inicio
                if (fechaFin < fechaInicio)
                {
                    litAlert.Text = "<div class='alert alert-danger'>La fecha de fin no puede ser anterior a la fecha de inicio.</div>";
                    return;
                }
                // Validación: En solicitud por rango, las fechas no deben ser iguales
                if (fechaInicio.Date == fechaFin.Date)
                {
                    litAlert.Text = "<div class='alert alert-danger'>Si es para 1 día, seleccione la opción '1 Día'.</div>";
                    return;
                }

                /*
                 * FERIADOS NACIONALES
                "2025-01-01", // Año Nuevo
                "2025-04-14", // dia de las americas
                "2025-04-17", // jueves santo
                "2025-04-18", //viernes santo
                "2025-04-19", // sabado santo
                "2025-04-20", //domingo de resurreccion
                "2025-09-15", //dia de la independencia
                "2025-10-03", //dia del soldado
                "2025-10-12", //dia de la raza
                "2025-10-21", //dia de las fuerzas armadas
                "2025-12-25"  // Navidad
                 */

                List<DateTime> feriados = new List<DateTime>
            {
                new DateTime(2024, 1, 1),
                new DateTime(2024, 4, 14),
                new DateTime(2024, 4, 17),
                new DateTime(2024, 4, 18),
                new DateTime(2024, 4, 19),
                new DateTime(2024, 4, 20),
                new DateTime(2024, 9, 15),
                new DateTime(2024, 10, 3),
                new DateTime(2024, 10, 12),
                new DateTime(2024, 10, 21),
                new DateTime(2024, 12, 25),
                new DateTime(2025, 1, 1),
                new DateTime(2025, 4, 14),
                new DateTime(2025, 4, 17),
                new DateTime(2025, 4, 18),
                new DateTime(2025, 4, 19),
                new DateTime(2025, 4, 20),
                new DateTime(2025, 9, 15),
                new DateTime(2025, 10, 3),
                new DateTime(2025, 10, 12),
                new DateTime(2025, 10, 21),
                new DateTime(2025, 12, 25)
            };

                //Calcular horas solicitadas en función de los días hábiles
                int diasHabiles = CalcularDiasHabiles(fechaInicio, fechaFin, feriados);
                horasSolicitadas = diasHabiles * 8;

                //Verificar que no se solicite más de lo disponible
                if (horasSolicitadas > horasDisponibles)
                {
                    litAlert.Text = "<div class='alert alert-danger'>No puede solicitar más horas (o días) de las disponibles.</div>";
                    return;
                }

            }
            else //Caso: Solicitud por horas (sin fecha fin)
            {
                fechaFin = fechaInicio;
                if (ddlHoras.SelectedValue == "0")
                {
                    litAlert.Text = "<div class='alert alert-danger'>Seleccione la cantidad de horas (entre 1 y 8).</div>";
                    return;
                }
                if (string.IsNullOrWhiteSpace(txtComentarios.Text))
                {
                    litAlert.Text = "<div class='alert alert-danger'>Para solicitudes por horas, indique en comentarios el rango horario de su ausencia.</div>";
                    return;
                }
                horasSolicitadas = Convert.ToInt32(ddlHoras.SelectedValue);

                // Validación: No solicitar más horas de las disponibles
                if (horasSolicitadas > horasDisponibles)
                {
                    litAlert.Text = "<div class='alert alert-danger'>No puede solicitar más horas de las disponibles.</div>";
                    return;
                }
            }

            //Luego de calcular horasSolicitadas (en cualquiera de los if/else)
            int diasSolicitados = (int)Math.Ceiling(horasSolicitadas / 8.0);

            //convertir las horas de la nueva solicitud a días
            int nuevosDiasSolicitados = (int)Math.Ceiling(horasSolicitadas / 8.0);

            //consultar cuntos días ya se han solicitado este mes para este tipo de permiso
            int diasSolicitadosAcumulados = 0;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string queryAcumulado = @"
                    SELECT ISNULL(SUM(CEILING(CAST(horas_solicitadas AS FLOAT) / 8.0)), 0)
                    FROM Permisos
                    WHERE id_empleado = @id_empleado
                      AND id_tipo_permiso = @id_tipo_permiso
                      AND MONTH(fecha_inicio) = @mes
                      AND YEAR(fecha_inicio) = @anio
                      AND estado IN ('pendiente','aprobado')";
                using (SqlCommand cmdAcum = new SqlCommand(queryAcumulado, conn))
                {
                    cmdAcum.Parameters.AddWithValue("@id_empleado", idEmpleado);
                    cmdAcum.Parameters.AddWithValue("@id_tipo_permiso", idTipoPermiso);
                    //usar la fecha de inicio de la solicitud actual para determinar el mes y año
                    cmdAcum.Parameters.AddWithValue("@mes", fechaInicio.Month);
                    cmdAcum.Parameters.AddWithValue("@anio", fechaInicio.Year);
                    diasSolicitadosAcumulados = Convert.ToInt32(cmdAcum.ExecuteScalar());
                }
            }

            //vaalidar que la suma de los días acumulados más la nueva solicitud no exceda el límite mensual
            int? diasMaxMensuales = null;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string queryTipo = "SELECT dias_maximos_mensuales FROM TiposPermisos WHERE id_tipo_permiso = @id_tipo_permiso";
                using (SqlCommand cmd = new SqlCommand(queryTipo, conn))
                {
                    cmd.Parameters.AddWithValue("@id_tipo_permiso", idTipoPermiso);
                    object result = cmd.ExecuteScalar();
                    if (result != null && result != DBNull.Value)
                    {
                        diasMaxMensuales = Convert.ToInt32(result);
                    }
                }
            }

            if (diasMaxMensuales.HasValue)
            {
                int totalDiasAcumulados = diasSolicitadosAcumulados + nuevosDiasSolicitados;
                if (totalDiasAcumulados > diasMaxMensuales.Value)
                {
                    litAlert.Text = $"<div class='alert alert-danger'>Se han solicitado {diasSolicitadosAcumulados} día(s) para este permiso en este mes, el límite mensual es de {diasMaxMensuales.Value} días.</div>";
                    return;
                }
            }

            //No duplicar permisos. Verificar si ya existe un permiso aprobado o pendiente en el mismo rango.
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string queryDup = @"
            SELECT COUNT(*) FROM Permisos 
            WHERE id_empleado = @id_empleado 
              AND id_tipo_permiso = @id_tipo_permiso 
              AND estado IN ('pendiente','aprobado')
              AND (
                    (@fechaInicio BETWEEN fecha_inicio AND ISNULL(fecha_fin, fecha_inicio))
                 OR (@fechaFin BETWEEN fecha_inicio AND ISNULL(fecha_fin, fecha_inicio))
                 OR (fecha_inicio BETWEEN @fechaInicio AND @fechaFin)
              )";
                using (SqlCommand cmdDup = new SqlCommand(queryDup, conn))
                {
                    cmdDup.Parameters.AddWithValue("@id_empleado", idEmpleado);
                    cmdDup.Parameters.AddWithValue("@id_tipo_permiso", idTipoPermiso);
                    cmdDup.Parameters.AddWithValue("@fechaInicio", fechaInicio);
                    cmdDup.Parameters.AddWithValue("@fechaFin", fechaFin);
                    int count = Convert.ToInt32(cmdDup.ExecuteScalar());
                    if (count > 0)
                    {
                        litAlert.Text = "<div class='alert alert-danger'>Ya existe un permiso en estado pendiente o aprobado en el rango seleccionado.</div>";
                        return;
                    }
                }
            }

            // Procesar la subida del documento
            string documentoRuta = null;
            if (fuDocumento.HasFile)
            {
                try
                {
                    string rutaDestino = Server.MapPath("~/Permisos/");
                    if (!Directory.Exists(rutaDestino))
                    {
                        Directory.CreateDirectory(rutaDestino);
                    }
                    string nombreArchivo = DateTime.Now.ToString("yyyyMMddHHmmss_") + Path.GetFileName(fuDocumento.FileName);
                    string rutaArchivo = Path.Combine(rutaDestino, nombreArchivo);
                    fuDocumento.SaveAs(rutaArchivo);
                    documentoRuta = rutaArchivo;
                }
                catch (Exception ex)
                {
                    litAlert.Text = "<div class='alert alert-danger'>Error al subir el documento: " + ex.Message + "</div>";
                    return;
                }
            }

            //insertar la solicitud en Permisos con estado 'pendiente'
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string insertQuery = @"
                    INSERT INTO Permisos 
                        (id_empleado, id_tipo_permiso, fecha_inicio, fecha_fin, estado, comentarios_empleado, documento, horas_solicitadas)
                    VALUES 
                        (@id_empleado, @id_tipo_permiso, @fecha_inicio, @fecha_fin, 'pendiente', @comentarios_empleado, @documento, @horas_solicitadas);
                    SELECT SCOPE_IDENTITY();";
                using (SqlCommand cmd = new SqlCommand(insertQuery, conn))
                {
                    cmd.Parameters.AddWithValue("@id_empleado", idEmpleado);
                    cmd.Parameters.AddWithValue("@id_tipo_permiso", idTipoPermiso);
                    cmd.Parameters.AddWithValue("@fecha_inicio", fechaInicio);
                    cmd.Parameters.AddWithValue("@fecha_fin", fechaFin);
                    cmd.Parameters.AddWithValue("@comentarios_empleado", txtComentarios.Text.Trim());
                    cmd.Parameters.AddWithValue("@horas_solicitadas", horasSolicitadas);
                    if (documentoRuta == null)
                        cmd.Parameters.AddWithValue("@documento", DBNull.Value);
                    else
                        cmd.Parameters.AddWithValue("@documento", documentoRuta);

                    int idPermiso = Convert.ToInt32(cmd.ExecuteScalar());
                    litAlert.Text = "<div class='alert alert-success'>Permiso solicitado correctamente.</div>";

                    //llamar al procedimiento para auto aprobar permiso
                    //solo si el permiso corresponde a 'Asueto'
                    if (ddlTipoPermiso.SelectedItem.Text.ToLower().Contains("asueto"))
                    {
                        using (SqlCommand cmdProc = new SqlCommand("EXEC AutoAprobarPermiso @id_permiso", conn))
                        {
                            cmdProc.Parameters.AddWithValue("@id_permiso", idPermiso);
                            cmdProc.ExecuteNonQuery();
                        }
                    }

                    NotificarSupervisoresYRH();

                    //Actualizar saldo del empleado para este tipo de permiso
                    ActualizarSaldoPermisos(idEmpleado, idTipoPermiso, !string.IsNullOrWhiteSpace(txtFechaFin.Text.Trim()), horasSolicitadas);
                    LimpiarFormulario();
                    ActualizarSaldo();
                    CargarPermisosPendientes();
                }
            }
        }


        //Actualiza el saldo en SaldoPermisos restando los días u horas solicitados.
        private void ActualizarSaldoPermisos(int idEmpleado, int idTipoPermiso, bool esSolicitudPorDias, int horasSolicitadas)
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "SELECT horas_disponibles FROM SaldoPermisos " +
                                "WHERE id_empleado = @id_empleado AND id_tipo_permiso = @id_tipo_permiso";

                double horasDisponibles = 0;
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id_empleado", idEmpleado);
                    cmd.Parameters.AddWithValue("@id_tipo_permiso", idTipoPermiso);
                    object result = cmd.ExecuteScalar();
                    if (result != null && result != DBNull.Value)
                    {
                        horasDisponibles = Convert.ToDouble(result);
                    }
                }

                if (esSolicitudPorDias)
                {
                    //Calcula los días solicitados en formato decimal (horasSolicitadas / 8.0)
                    double nuevosHoras = horasDisponibles - horasSolicitadas;
                    string update = "UPDATE SaldoPermisos SET horas_disponibles = @nuevosHoras " +
                                    "WHERE id_empleado = @id_empleado AND id_tipo_permiso = @id_tipo_permiso";
                    using (SqlCommand cmd = new SqlCommand(update, conn))
                    {
                        cmd.Parameters.AddWithValue("@nuevosHoras", nuevosHoras);
                        cmd.Parameters.AddWithValue("@id_empleado", idEmpleado);
                        cmd.Parameters.AddWithValue("@id_tipo_permiso", idTipoPermiso);
                        int filasAfectadas = cmd.ExecuteNonQuery();
                        if (filasAfectadas == 0)
                        {
                            //Si no existe registro, insertar uno nuevo con el saldo inicial menos lo solicitado
                            string queryTipo = "SELECT dias_maximos_anuales FROM TiposPermisos WHERE id_tipo_permiso = @id_tipo_permiso";
                            using (SqlCommand cmdTipo = new SqlCommand(queryTipo, conn))
                            {
                                cmdTipo.Parameters.AddWithValue("@id_tipo_permiso", idTipoPermiso);
                                object result = cmdTipo.ExecuteScalar();
                                int saldoInicial = result != null && result != DBNull.Value ? Convert.ToInt32(result) : 0;
                                double saldoInicialHoras = saldoInicial * 8.0;
                                double saldoRestanteHoras = saldoInicialHoras - horasSolicitadas;
                                string insertSaldo = "INSERT INTO SaldoPermisos (id_empleado, id_tipo_permiso, horas_disponibles) " +
                                                     "VALUES (@id_empleado, @id_tipo_permiso, @saldoRestanteHoras)";
                                using (SqlCommand cmdInsert = new SqlCommand(insertSaldo, conn))
                                {
                                    cmdInsert.Parameters.AddWithValue("@id_empleado", idEmpleado);
                                    cmdInsert.Parameters.AddWithValue("@id_tipo_permiso", idTipoPermiso);
                                    cmdInsert.Parameters.AddWithValue("@saldoRestanteHoras", saldoRestanteHoras);
                                    cmdInsert.ExecuteNonQuery();
                                }
                            }
                        }
                    }
                }
                else
                {
                    //Solicitud por horas: descuenta directamente en horas
                    double nuevosHoras = horasDisponibles - horasSolicitadas;
                    string update = "UPDATE SaldoPermisos SET horas_disponibles = @nuevosHoras " +
                                    "WHERE id_empleado = @id_empleado AND id_tipo_permiso = @id_tipo_permiso";
                    using (SqlCommand cmd = new SqlCommand(update, conn))
                    {
                        cmd.Parameters.AddWithValue("@nuevosHoras", nuevosHoras);
                        cmd.Parameters.AddWithValue("@id_empleado", idEmpleado);
                        cmd.Parameters.AddWithValue("@id_tipo_permiso", idTipoPermiso);
                        int filasAfectadas = cmd.ExecuteNonQuery();
                        if (filasAfectadas == 0)
                        {
                            string queryTipo = "SELECT dias_maximos_anuales FROM TiposPermisos WHERE id_tipo_permiso = @id_tipo_permiso";
                            using (SqlCommand cmdTipo = new SqlCommand(queryTipo, conn))
                            {
                                cmdTipo.Parameters.AddWithValue("@id_tipo_permiso", idTipoPermiso);
                                object result = cmdTipo.ExecuteScalar();
                                int saldoInicial = result != null && result != DBNull.Value ? Convert.ToInt32(result) : 0;
                                double saldoInicialHoras = saldoInicial * 8.0;
                                double saldoRestanteHoras = saldoInicialHoras - horasSolicitadas;
                                string insertSaldo = "INSERT INTO SaldoPermisos (id_empleado, id_tipo_permiso, horas_disponibles) " +
                                                     "VALUES (@id_empleado, @id_tipo_permiso, @saldoRestanteHoras)";
                                using (SqlCommand cmdInsert = new SqlCommand(insertSaldo, conn))
                                {
                                    cmdInsert.Parameters.AddWithValue("@id_empleado", idEmpleado);
                                    cmdInsert.Parameters.AddWithValue("@id_tipo_permiso", idTipoPermiso);
                                    cmdInsert.Parameters.AddWithValue("@saldoRestanteHoras", saldoRestanteHoras);
                                    cmdInsert.ExecuteNonQuery();
                                }
                            }
                        }
                    }
                }
            }
        }

        // Calcula los días hábiles (excluyendo sábados y domingos) entre dos fechas.
        /*
        private int CalcularDiasHabiles(DateTime inicio, DateTime fin)
        {
            int diasHabiles = 0;
            for (DateTime fecha = inicio.Date; fecha <= fin.Date; fecha = fecha.AddDays(1))
            {
                if (fecha.DayOfWeek != DayOfWeek.Saturday && fecha.DayOfWeek != DayOfWeek.Sunday)
                    diasHabiles++;
            }
            return diasHabiles;
        }
        */

        private int CalcularDiasHabiles(DateTime inicio, DateTime fin, List<DateTime> feriados)
        {
            int diasHabiles = 0;
            for (DateTime fecha = inicio.Date; fecha <= fin.Date; fecha = fecha.AddDays(1))
            {
                // Excluir sábados, domingos y feriados
                if (fecha.DayOfWeek != DayOfWeek.Saturday &&
                    fecha.DayOfWeek != DayOfWeek.Sunday &&
                    (feriados == null || !feriados.Contains(fecha)))
                {
                    diasHabiles++;
                }
            }
            return diasHabiles;
        }

        protected void btnCancelar_Click(object sender, EventArgs e)
        {
            litAlert.Text = "";
            LimpiarFormulario();

        }

        private void LimpiarFormulario()
        {
            // Limpiar valores de los controles
            ddlTipoPermiso.SelectedIndex = 0;
            txtFechaInicio.Text = "";
            txtFechaFin.Text = "";
            ddlHoras.SelectedValue = "0";
            txtComentarios.Text = "";
            //reinicia el control FileUpload
            fuDocumento.Dispose();

            //restablecer la selección de los radio buttons
            rbDias.Checked = true;
            rbHoras.Checked = false;
            rbUnDia.Checked = false;

            //Restaurar el estado inicial de los controles:
            //se asume que la opción "Días" está seleccionada:
            //Fecha Fin habilitado y ddlHoras deshabilitado con fondo gris claro.
            txtFechaFin.Enabled = true;
            txtFechaFin.BackColor = System.Drawing.Color.Empty;
            ddlHoras.Enabled = false;
            ddlHoras.BackColor = System.Drawing.ColorTranslator.FromHtml("#e9ecef");
        }

        private void CargarPermisosPendientes()
        {
            int idEmpleado = Session["id_empleado"] != null ? Convert.ToInt32(Session["id_empleado"]) : 0;
            if (idEmpleado == 0) return;

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                // Se filtran solo los permisos pendientes
                string query = @"
                    SELECT 
                        p.id_permiso,
                        tp.nombre_permiso,
                        p.fecha_inicio,
                        p.fecha_fin,
                        p.horas_solicitadas,
                        p.estado
                    FROM Permisos p
                    INNER JOIN TiposPermisos tp ON p.id_tipo_permiso = tp.id_tipo_permiso
                    WHERE p.id_empleado = @id_empleado AND p.estado = 'pendiente'
                    ORDER BY p.fecha_solicitud DESC";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id_empleado", idEmpleado);
                    SqlDataReader reader = cmd.ExecuteReader();
                    repeaterPendientes.DataSource = reader;
                    repeaterPendientes.DataBind();
                }
            }

        }

        //metodo para insertar una notificación en la tabla Notificaciones
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

        private void NotificarSupervisoresYRH()
        {
            //Obtener el id del empleado solicitante
            int idEmpleadoSolicitante = Convert.ToInt32(Session["id_empleado"]);
            string nombreSolicitante = Session["nombreCompleto"] != null
                                ? Session["nombreCompleto"].ToString()
                                : Session["username"].ToString();
            int deptId = 0;

            //Obtener el departamento del empleado solicitante de la tabla Empleados
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string queryDept = "SELECT id_departamento FROM Empleados WHERE id_empleado = @id_empleado";
                using (SqlCommand cmd = new SqlCommand(queryDept, conn))
                {
                    cmd.Parameters.AddWithValue("@id_empleado", idEmpleadoSolicitante);
                    object result = cmd.ExecuteScalar();
                    if (result != null && result != DBNull.Value)
                    {
                        deptId = Convert.ToInt32(result);
                    }
                }
            }

            //Lista para almacenar los id_empleado de los supervisores y RH
            List<int> idsNotificar = new List<int>();

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                //Seleccionar supervisores: aquellos que tengan un valor en id_supervisor_departamento
                //y pertenezcan al mismo departamento que el empleado solicitante.
                string querySupervisores = @"
            SELECT id_empleado 
            FROM Empleados 
            WHERE id_supervisor_departamento IS NOT NULL 
              AND id_supervisor_departamento <> 0
              AND id_departamento = @deptId";
                using (SqlCommand cmd = new SqlCommand(querySupervisores, conn))
                {
                    cmd.Parameters.AddWithValue("@deptId", deptId);
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            idsNotificar.Add(Convert.ToInt32(reader["id_empleado"]));
                        }
                    }
                }

                //Seleccionar a los RH. Suponemos que los RH se identifican en la tabla Usuarios con rol 'rh'
                //y que existe un join entre Usuarios y Empleados (por ejemplo, el id de usuario coincide con id_empleado).
                string queryRH = @"
            SELECT e.id_empleado 
            FROM Empleados e
            INNER JOIN Usuarios u ON e.id_empleado = u.id_usuario
            WHERE LOWER(u.rol) = 'rh'";
                using (SqlCommand cmd = new SqlCommand(queryRH, conn))
                {
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            int idRH = Convert.ToInt32(reader["id_empleado"]);
                            // Evitar duplicados
                            if (!idsNotificar.Contains(idRH))
                                idsNotificar.Add(idRH);
                        }
                    }
                }
            }

            //Construir el mensaje usando el nombre del solicitante.
            string mensaje = $"Nuevo permiso solicitado por {nombreSolicitante}";

            //Insertar la notificación para cada usuario (supervisor o RH)
            foreach (int id in idsNotificar)
            {
                InsertarNotificacion(id, mensaje, "PermisoSolicitado");
            }
        }



    }
}
