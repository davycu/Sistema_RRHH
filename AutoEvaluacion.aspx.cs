using Sistema_RRHH.Clases;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Sistema_RRHH
{
    public partial class AutoEvaluacion : System.Web.UI.Page
    {
        string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;
        protected void Page_Load(object sender, EventArgs e)
        {

            if (Session["username"] == null)
            {
                Response.Redirect("Login.aspx");
                return;
            }
            if (!IsPostBack)
            {
                CargarAniosDisponibles();
                CargarDatosEmpleado();
            }
        }

        private void CargarAniosDisponibles()
        {
            List<int> anios = new List<int>();
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "SELECT DISTINCT anio FROM PeriodosEvaluacion ORDER BY anio";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            anios.Add(Convert.ToInt32(reader["anio"]));
                        }
                    }
                }
            }
            ddlAnios.DataSource = anios;
            ddlAnios.DataBind();
            ddlAnios.Items.Insert(0, new ListItem("Seleccione un año", "0"));
        }

        protected void CargarDatosEmpleado()
        {
            if (Session["fecha_ingreso"] != null)
            {
                DateTime fechaIngreso = Convert.ToDateTime(Session["fecha_ingreso"]);
                //Formatear la fecha de ingreso en formato "dd de MMMM del yyyy" (ej. 06 de marzo del 2025)
                CultureInfo ci = new CultureInfo("es-ES");
                lblFechaIngreso.Text = fechaIngreso.ToString("dd 'de' MMMM 'del' yyyy", ci);

                //Calcular antigüedad en años, meses y días
                DateTime now = DateTime.Now;
                int years = now.Year - fechaIngreso.Year;
                int months = now.Month - fechaIngreso.Month;
                int days = now.Day - fechaIngreso.Day;

                if (days < 0)
                {
                    months--;
                    //Obtener los días del mes anterior
                    int diasMesAnterior = DateTime.DaysInMonth(now.Year, now.Month == 1 ? 12 : now.Month - 1);
                    days += diasMesAnterior;
                }

                if (months < 0)
                {
                    years--;
                    months += 12;
                }

                lblAntiguedad.Text = $"{years} año(s), {months} mes(es) y {days} día(s)";
            }
            else
            {
                lblFechaIngreso.Text = "No disponible";
                lblAntiguedad.Text = "No disponible";
            }
        }


        protected void btnCargarPreguntas_Click(object sender, EventArgs e)
        {

            //Limpiar el repeater y ocultar el panel antes de cargar el nuevo periodo
            rptPreguntas.DataSource = null;
            rptPreguntas.DataBind();
            pnlPreguntas.Visible = false;

            litMensaje.Text = "";
            litEvaluadoPor.Text = "";

            //Limpiar retroalimentación de evaluaciones previas
            litRetroalimentacion.Text = "";
            pnlRetroalimentacion.Visible = false;

            int anio, trimestre;
            if (!int.TryParse(ddlAnios.SelectedValue, out anio) || anio == 0)
            {
                litMensaje.Text = "<div class='alert alert-danger'>Seleccione un año válido.</div>";
                return;
            }
            if (!int.TryParse(ddlTrimestres.SelectedValue, out trimestre))
            {
                litMensaje.Text = "<div class='alert alert-danger'>Seleccione un trimestre válido.</div>";
                return;
            }
            //Verificar si el empleado puede autoevaluarse en el periodo seleccionado.
            DateTime fechaIngreso = Convert.ToDateTime(Session["fecha_ingreso"]); // se guarda en sesión
            PeriodoEvaluacion periodo = ObtenerPeriodo(anio, trimestre);
            if (periodo == null)
            {
                litMensaje.Text = "<div class='alert alert-danger'>No se encontró el periodo seleccionado.</div>";
                return;
            }
            //Si el empleado ingresó después del inicio del periodo, puede autoevaluarse; de lo contrario, se bloquea.
            if (fechaIngreso > periodo.fecha_fin)
            {
                litMensaje.Text = "<div class='alert alert-danger'>No puede autoevaluarse en este periodo.</div>";
                return;
            }

            int idEvaluacion = ObtenerIdEvaluacion();

            //Cargar las preguntas asignadas para el periodo seleccionado
            List<Pregunta> preguntas = ObtenerPreguntasPorPeriodo(anio, trimestre);
            if (preguntas.Count > 0)
            {
                rptPreguntas.DataSource = preguntas;
                rptPreguntas.DataBind();
                pnlPreguntas.Visible = true;

                if (EvaluacionFinalizada(idEvaluacion))
                {
                    //Siempre cargar las respuestas originales del empleado
                    CargarRespuestas(idEvaluacion);
                    VerificarYMostrarRetroalimentacion(idEvaluacion);
                    CargarEvaluadoPor(idEvaluacion);

                        //Deshabilitar cada control dentro del repeater para evitar edición
                        foreach (RepeaterItem item in rptPreguntas.Items)
                        {
                            DropDownList ddlPuntaje = (DropDownList)item.FindControl("ddlPuntaje");
                            TextBox txtComentario = (TextBox)item.FindControl("txtComentario");
                            if (ddlPuntaje != null)
                                ddlPuntaje.Enabled = false;
                            if (txtComentario != null)
                                txtComentario.Enabled = false;
                        }
                        btnGuardarAutoevaluacion.Visible = false;
                        btnCancelar.Visible = false;
                        litMensaje.Text = "<div class='alert alert-success'>Evaluación finalizada. No se puede editar.</div>";
                }
                    else
                    {
                        btnGuardarAutoevaluacion.Visible = true;
                        btnCancelar.Visible = true;
                    }
            }
                else
                {
                    litMensaje.Text = "<div class='alert alert-info'>No hay preguntas para este periodo.</div>";
                }
        }
        
        

        private bool EvaluacionFinalizada(int idEvaluacion)
        {
            bool finalizada = false;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "SELECT finalizada FROM Evaluaciones WHERE id_evaluacion = @idEvaluacion";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@idEvaluacion", idEvaluacion);
                    object result = cmd.ExecuteScalar();
                    if (result != null && result != DBNull.Value)
                    {
                        finalizada = Convert.ToBoolean(result);
                    }
                }
            }
            return finalizada;
        }

        private void CargarRespuestas(int idEvaluacion)
        {
            //Creamos un diccionario para ubicar cada id_pregunta a su respuesta
            Dictionary<int, EvaluacionPregunta> dictRespuestas = new Dictionary<int, EvaluacionPregunta>();
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = @"
            SELECT id_pregunta, puntaje_empleado, comentario_empleado
            FROM EvaluacionesPreguntas
            WHERE id_evaluacion = @idEvaluacion";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@idEvaluacion", idEvaluacion);
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            int idPregunta = Convert.ToInt32(reader["id_pregunta"]);
                            EvaluacionPregunta resp = new EvaluacionPregunta
                            {
                                id_pregunta = idPregunta,
                                puntaje_empleado = Convert.ToInt32(reader["puntaje_empleado"]),
                                comentario_empleado = reader["comentario_empleado"].ToString()
                            };
                            dictRespuestas[idPregunta] = resp;
                        }
                    }
                }
            }
            //Recorrer el repeater y, si hay respuesta para esa pregunta, asignarla a los controles.
            foreach (RepeaterItem item in rptPreguntas.Items)
            {
                HiddenField hfIdPregunta = (HiddenField)item.FindControl("hfIdPregunta");
                DropDownList ddlPuntaje = (DropDownList)item.FindControl("ddlPuntaje");
                TextBox txtComentario = (TextBox)item.FindControl("txtComentario");
                if (hfIdPregunta != null && ddlPuntaje != null && txtComentario != null)
                {
                    int idPregunta = Convert.ToInt32(hfIdPregunta.Value);
                    if (dictRespuestas.ContainsKey(idPregunta))
                    {
                        EvaluacionPregunta resp = dictRespuestas[idPregunta];
                        ddlPuntaje.SelectedValue = resp.puntaje_empleado.ToString();
                        txtComentario.Text = resp.comentario_empleado;
                    }
                }
            }
        }



        private PeriodoEvaluacion ObtenerPeriodo(int anio, int trimestre)
        {
            PeriodoEvaluacion periodo = null;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "SELECT TOP 1 * FROM PeriodosEvaluacion WHERE anio = @anio AND trimestre = @trimestre";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@anio", anio);
                    cmd.Parameters.AddWithValue("@trimestre", trimestre);
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            periodo = new PeriodoEvaluacion
                            {
                                id_periodo = Convert.ToInt32(reader["id_periodo"]),
                                anio = Convert.ToInt32(reader["anio"]),
                                trimestre = Convert.ToInt32(reader["trimestre"]),
                                fecha_inicio = Convert.ToDateTime(reader["fecha_inicio"]),
                                fecha_fin = Convert.ToDateTime(reader["fecha_fin"])
                            };
                        }
                    }
                }
            }
            return periodo;
        }

        private List<Pregunta> ObtenerPreguntasPorPeriodo(int anio, int trimestre)
        {
            List<Pregunta> preguntas = new List<Pregunta>();
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = @"
                    SELECT pr.id_pregunta, pr.texto_pregunta, pr.seccion
                    FROM PreguntasPeriodos pp
                    INNER JOIN Preguntas pr ON pp.id_pregunta = pr.id_pregunta
                    INNER JOIN PeriodosEvaluacion pe ON pp.id_periodo = pe.id_periodo
                    WHERE pe.anio = @anio AND pe.trimestre = @trimestre";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@anio", anio);
                    cmd.Parameters.AddWithValue("@trimestre", trimestre);
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            preguntas.Add(new Pregunta
                            {
                                id_pregunta = Convert.ToInt32(reader["id_pregunta"]),
                                texto_pregunta = reader["texto_pregunta"].ToString(),
                                seccion = reader["seccion"].ToString()
                            });
                        }
                    }
                }
            }
            return preguntas;
        }

        protected void btnGuardarAutoevaluacion_Click(object sender, EventArgs e)
        {
            //aqui el empleado ya ha completado la autoevaluación en el periodo seleccionado.
            //Se obtiene o crea una Evaluación para este empleado y periodo.
            int idEvaluacion = ObtenerIdEvaluacion();

            //Recorre cada pregunta en el repeater para validar y luego guardar las respuestas
            foreach (RepeaterItem item in rptPreguntas.Items)
            {
                TextBox txtComentario = (TextBox)item.FindControl("txtComentario");

                //Validar que el comentario no esté vacío
                if (string.IsNullOrEmpty(txtComentario.Text.Trim()))
                {
                    litMensaje.Text = "<div class='alert alert-danger'>Debe ingresar un comentario para cada pregunta.</div>";
                    return; // Cancela el save si falta algún comentario
                }
            }

            //Recorrer cada pregunta en el repeater para guardar las respuestas
            foreach (RepeaterItem item in rptPreguntas.Items)
                    {
                        DropDownList ddlPuntaje = (DropDownList)item.FindControl("ddlPuntaje");
                        TextBox txtComentario = (TextBox)item.FindControl("txtComentario");
                        HiddenField hfIdPregunta = (HiddenField)item.FindControl("hfIdPregunta");

                        int puntaje = Convert.ToInt32(ddlPuntaje.SelectedValue);
                        string comentario = txtComentario.Text.Trim();
                        int idPregunta = Convert.ToInt32(hfIdPregunta.Value);

                        using (SqlConnection conn = new SqlConnection(connectionString))
                        {
                            conn.Open();
                            string query = @"
                            INSERT INTO EvaluacionesPreguntas (id_evaluacion, id_pregunta, puntaje_empleado, puntaje_supervisor, comentario_empleado, comentario_supervisor)
                            VALUES (@idEvaluacion, @idPregunta, @puntaje, 0, @comentario, NULL)";
                    using (SqlCommand cmd = new SqlCommand(query, conn))
                            {
                                cmd.Parameters.AddWithValue("@idEvaluacion", idEvaluacion);
                                cmd.Parameters.AddWithValue("@idPregunta", idPregunta);
                                cmd.Parameters.AddWithValue("@puntaje", puntaje);
                                cmd.Parameters.AddWithValue("@comentario", comentario);
                                cmd.ExecuteNonQuery();
                            }
                        }
                    }

            //Actualizar la evaluación para marcarla como finalizada
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string updateEval = "UPDATE Evaluaciones SET finalizada = 1 WHERE id_evaluacion = @idEvaluacion";
                using (SqlCommand cmd = new SqlCommand(updateEval, conn))
                {
                    cmd.Parameters.AddWithValue("@idEvaluacion", idEvaluacion);
                    cmd.ExecuteNonQuery();
                }
            }

            NotificarSupervisorAutoevaluacion();

            //Bloquear edición de la evaluación
            foreach (RepeaterItem item in rptPreguntas.Items)
            {
                DropDownList ddlPuntaje = (DropDownList)item.FindControl("ddlPuntaje");
                TextBox txtComentario = (TextBox)item.FindControl("txtComentario");
                if (ddlPuntaje != null)
                    ddlPuntaje.Enabled = false;
                if (txtComentario != null)
                    txtComentario.Enabled = false;
            }
            btnGuardarAutoevaluacion.Visible = false;
            btnCancelar.Visible = false;
            litMensaje.Text = "<div class='alert alert-success'>Autoevaluación guardada correctamente.</div>";
        }

        private int ObtenerIdEvaluacion()
        {
            int idEvaluacion = 0;
            int idEmpleado = Convert.ToInt32(Session["id_empleado"]);
            int anio = Convert.ToInt32(ddlAnios.SelectedValue);
            int trimestre = Convert.ToInt32(ddlTrimestres.SelectedValue);
            PeriodoEvaluacion periodo = ObtenerPeriodo(anio, trimestre);
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "SELECT id_evaluacion FROM Evaluaciones WHERE id_empleado = @idEmpleado AND id_periodo = @idPeriodo";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@idEmpleado", idEmpleado);
                    cmd.Parameters.AddWithValue("@idPeriodo", periodo.id_periodo);
                    object result = cmd.ExecuteScalar();
                    if (result != null && result != DBNull.Value)
                    {
                        idEvaluacion = Convert.ToInt32(result);
                    }
                    else
                    {
                        //Insertar nueva evaluación
                        string insert = "INSERT INTO Evaluaciones (id_empleado, fecha_evaluacion, id_supervisor, id_periodo) " +
                                    "VALUES (@idEmpleado, @fechaEvaluacion, @idSupervisor, @idPeriodo); SELECT SCOPE_IDENTITY();";
                        using (SqlCommand cmdInsert = new SqlCommand(insert, conn))
                        {
                            cmdInsert.Parameters.AddWithValue("@idEmpleado", idEmpleado);
                            cmdInsert.Parameters.AddWithValue("@fechaEvaluacion", DateTime.Now);
                            cmdInsert.Parameters.AddWithValue("@idSupervisor", DBNull.Value); // NULL por mientras se evalua.
                            cmdInsert.Parameters.AddWithValue("@idPeriodo", periodo.id_periodo);
                            idEvaluacion = Convert.ToInt32(cmdInsert.ExecuteScalar());
                        }
                    }
                }
            }
            return idEvaluacion;
        }

        private void CargarRetroalimentacion(int idEvaluacion)
        {
           
            //Consulta para obtener la retroalimentación por pregunta
            StringBuilder sb = new StringBuilder();
            DataTable dt = new DataTable();
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = @"
            SELECT p.texto_pregunta, ep.puntaje_supervisor, ep.comentario_supervisor
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

            //Construir el HTML para la retroalimentación
            if (dt.Rows.Count > 0)
            {
                sb.Append("<table class='table table-bordered'>");
                sb.Append("<thead><tr><th>Pregunta</th><th>Puntaje Supervisor</th><th>Comentario Supervisor</th></tr></thead>");
                sb.Append("<tbody>");
                foreach (DataRow row in dt.Rows)
                {
                    sb.Append("<tr>");
                    sb.AppendFormat("<td>{0}</td>", row["texto_pregunta"]);
                    sb.AppendFormat("<td>{0}</td>", row["puntaje_supervisor"]);
                    sb.AppendFormat("<td>{0}</td>", row["comentario_supervisor"]);
                    sb.Append("</tr>");
                }
                sb.Append("</tbody></table>");
            }
            else
            {
                sb.Append("<div class='alert alert-info'>La evaluación aún no cuenta con retroalimentación por pregunta.</div>");
            }

            //Consultar el comentario general directamente aquí
            string comentarioGeneral = "";
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "SELECT comentarios_supervisor FROM Evaluaciones WHERE id_evaluacion = @idEvaluacion";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@idEvaluacion", idEvaluacion);
                    object result = cmd.ExecuteScalar();
                    if (result != null && result != DBNull.Value)
                    {
                        comentarioGeneral = result.ToString();
                    }
                }
            }

            //Agregar el comentario general al HTML
            if (!string.IsNullOrEmpty(comentarioGeneral))
            {
                sb.Append("<div class='card mt-3'>");
                sb.Append("<div class='card-header'><strong>Comentarios generales</strong></div>");
                sb.Append("<div class='card-body'>");
                sb.Append(comentarioGeneral);
                sb.Append("</div></div>");
            }

            litRetroalimentacion.Text = sb.ToString();
            pnlRetroalimentacion.Visible = true;
        }

        private void VerificarYMostrarRetroalimentacion(int idEvaluacion)
        {
            bool evaluada = false;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "SELECT EvaluadaSupervisor FROM Evaluaciones WHERE id_evaluacion = @idEvaluacion";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@idEvaluacion", idEvaluacion);
                    object result = cmd.ExecuteScalar();
                    if (result != null && result != DBNull.Value)
                    {
                        evaluada = Convert.ToBoolean(result);
                    }
                }
            }

            if (evaluada)
            {
                CargarRetroalimentacion(idEvaluacion);
                
            }
            else
            {
                pnlRetroalimentacion.Visible = false;
            }
        }

        private void CargarEvaluadoPor(int idEvaluacion)
        {
            string evaluadoPor = "";
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "SELECT EvaluadoPor FROM Evaluaciones WHERE id_evaluacion = @idEvaluacion";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@idEvaluacion", idEvaluacion);
                    object result = cmd.ExecuteScalar();
                    if (result != null && result != DBNull.Value)
                    {
                        evaluadoPor = result.ToString();
                    }
                }
            }
            //Asigna el mensaje solo si se obtuvo un valor
            if (!string.IsNullOrEmpty(evaluadoPor))
            {
                litEvaluadoPor.Text = "<div class='alert alert-success permanent-alert'><i class='fa fa-check-circle'></i> Su autoevaluación, ya ha sido evaluada por: <strong><em>" + evaluadoPor + "</em></strong>.<br />   Revisar abajo su retroalimentación.</div>";
            }
            else
            {
                litEvaluadoPor.Text = "";
            }
        }

        //metodo para notificar al supervisor cuando el empleado completa su autoevaluación.
        private void NotificarSupervisorAutoevaluacion()
        {
            //Obtiene el id del empleado que completa la autoevaluación
            int idEmpleado = Convert.ToInt32(Session["id_empleado"]);
            //Obtiene el username del empleado
            string nombreEmpleado = Session["nombreCompleto"] != null
                                ? Session["nombreCompleto"].ToString()
                                : Session["username"].ToString();

            int idDepartamento = 0;
            //Primero, obtenemos el departamento del empleado
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string queryDept = "SELECT id_departamento FROM Empleados WHERE id_empleado = @id_empleado";
                using (SqlCommand cmd = new SqlCommand(queryDept, conn))
                {
                    cmd.Parameters.AddWithValue("@id_empleado", idEmpleado);
                    object resultDept = cmd.ExecuteScalar();
                    if (resultDept != null && resultDept != DBNull.Value)
                    {
                        idDepartamento = Convert.ToInt32(resultDept);
                    }
                }
            }

            //buscamos en la tabla SupervisoresDepartamento un supervisor para ese departamento.
            int idSupervisor = 0;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                //buscar en SupervisoresDepartamento los registros (id_empleado, id_departamento)
                string querySup = "SELECT TOP 1 id_empleado FROM SupervisoresDepartamento WHERE id_departamento = @id_departamento";
                using (SqlCommand cmd = new SqlCommand(querySup, conn))
                {
                    cmd.Parameters.AddWithValue("@id_departamento", idDepartamento);
                    object resultSup = cmd.ExecuteScalar();
                    if (resultSup != null && resultSup != DBNull.Value)
                    {
                        idSupervisor = Convert.ToInt32(resultSup);
                    }
                }
            }

            //si se encontró un supervisor, se inserta la notificación
            if (idSupervisor > 0)
            {
                string mensaje = $"{nombreEmpleado} ha completado una autoevaluación.";
                InsertarNotificacion(idSupervisor, mensaje, "AutoevaluacionCompleta");
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

        protected void btnCancelar_Click(object sender, EventArgs e)
        {
            LimpiarRespuestas();
        }

        private void LimpiarRespuestas()
        {
            //Recorre cada item del repeater y restablece los controles.
            foreach (RepeaterItem item in rptPreguntas.Items)
            {
                DropDownList ddlPuntaje = (DropDownList)item.FindControl("ddlPuntaje");
                TextBox txtComentario = (TextBox)item.FindControl("txtComentario");
                if (ddlPuntaje != null)
                    ddlPuntaje.SelectedIndex = 0;
                if (txtComentario != null)
                    txtComentario.Text = "";
            }
        }
    }
}




  