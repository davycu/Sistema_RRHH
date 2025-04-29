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
    public partial class AprobarPermiso : System.Web.UI.Page
    {
        string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;
        protected void Page_Load(object sender, EventArgs e)
        {

            //Verificar que el usuario esté autenticado y tenga el rol adecuado
            Seguridad.VerificarSupervisor(this);

            if (!IsPostBack)
            {
                CargarPermisosPendientes();
                CargarHistorial();
            }
        }

        private void CargarPermisosPendientes()
        {
            int idEmpleado = Session["id_empleado"] != null ? Convert.ToInt32(Session["id_empleado"]) : 0;
            string rol = Session["rol"].ToString().ToLower();
            int supervisorDepto = 0;
            if (rol == "supervisor" && Session["id_departamento"] != null)
            {
                supervisorDepto = Convert.ToInt32(Session["id_departamento"]);
            }
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "";
                if (rol == "supervisor")
                {
                    query = @"
                        SELECT p.id_permiso, tp.nombre_permiso, e.nombre, e.apellido, 
                               p.fecha_inicio, p.fecha_fin, p.horas_solicitadas, p.fecha_solicitud, 
                               p.estado, p.comentarios_empleado, p.comentarios_supervisor, p.documento, 
                               p.revisado_por, p.fecha_revisado
                        FROM Permisos p
                        INNER JOIN TiposPermisos tp ON p.id_tipo_permiso = tp.id_tipo_permiso
                        INNER JOIN Empleados e ON p.id_empleado = e.id_empleado
                        WHERE e.id_departamento = @id_departamento
                          AND p.estado = 'pendiente'
                        ORDER BY p.fecha_solicitud DESC";
                }
                else
                {
                    query = @"
                        SELECT p.id_permiso, tp.nombre_permiso, e.nombre, e.apellido, 
                               p.fecha_inicio, p.fecha_fin, p.horas_solicitadas, p.fecha_solicitud, 
                               p.estado, p.comentarios_empleado, p.comentarios_supervisor, p.documento, 
                               p.revisado_por, p.fecha_revisado
                        FROM Permisos p
                        INNER JOIN TiposPermisos tp ON p.id_tipo_permiso = tp.id_tipo_permiso
                        INNER JOIN Empleados e ON p.id_empleado = e.id_empleado
                        WHERE p.estado = 'pendiente'
                        ORDER BY p.fecha_solicitud DESC";
                }
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    if (rol == "supervisor")
                        cmd.Parameters.AddWithValue("@id_departamento", supervisorDepto);
                    SqlDataReader reader = cmd.ExecuteReader();
                    repeaterPendientes.DataSource = reader;
                    repeaterPendientes.DataBind();
                }
            }
        }

        private void CargarHistorial()
        {
            string rol = Session["rol"].ToString().ToLower();
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "";
                if (rol == "supervisor")
                {
                    int supervisorId = Convert.ToInt32(Session["id_empleado"]);
                    //Se obtiene el departamento del supervisor desde la sesión (o se obtiene de la tabla Empleados)
                    int supervisorDepto = Session["id_departamento"] != null ? Convert.ToInt32(Session["id_departamento"]) : 0;
                    query = @"
                        SELECT p.id_permiso, tp.codigo_permiso, tp.nombre_permiso, e.nombre, e.apellido, 
                               p.fecha_inicio, p.fecha_fin, p.horas_solicitadas, p.fecha_solicitud, 
                               p.estado, p.documento, p.comentarios_empleado, p.comentarios_supervisor,
                               p.revisado_por, p.fecha_revisado
                        FROM Permisos p
                        INNER JOIN TiposPermisos tp ON p.id_tipo_permiso = tp.id_tipo_permiso
                        INNER JOIN Empleados e ON p.id_empleado = e.id_empleado
                        WHERE p.estado IN ('aprobado','rechazado')
                          AND e.id_departamento = @id_departamento
                          AND e.id_empleado <> @idSupervisor
                        ORDER BY p.fecha_solicitud DESC";
                    using (SqlCommand cmd = new SqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("@id_departamento", supervisorDepto);
                        cmd.Parameters.AddWithValue("@idSupervisor", supervisorId);
                        SqlDataReader reader = cmd.ExecuteReader();
                        repeaterHistorial.DataSource = reader;
                        repeaterHistorial.DataBind();
                    }
                }
                else //Para Admin y HR, se muestran todos
                {
                    query = @"
                SELECT p.id_permiso, tp.codigo_permiso, tp.nombre_permiso, e.nombre, e.apellido, 
                       p.fecha_inicio, p.fecha_fin, p.horas_solicitadas, p.fecha_solicitud, 
                       p.estado, p.documento, p.comentarios_empleado, p.comentarios_supervisor,
                       p.revisado_por, p.fecha_revisado
                FROM Permisos p
                INNER JOIN TiposPermisos tp ON p.id_tipo_permiso = tp.id_tipo_permiso
                INNER JOIN Empleados e ON p.id_empleado = e.id_empleado
                WHERE p.estado IN ('aprobado','rechazado')
                ORDER BY p.fecha_solicitud DESC";
                    using (SqlCommand cmd = new SqlCommand(query, conn))
                    {
                        SqlDataReader reader = cmd.ExecuteReader();
                        repeaterHistorial.DataSource = reader;
                        repeaterHistorial.DataBind();
                    }
                }
            }
        }

        /*
        private void CargarHistorial()
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = @"
                    SELECT p.id_permiso, tp.codigo_permiso, tp.nombre_permiso, e.nombre, e.apellido, 
                           p.fecha_inicio, p.fecha_fin, p.horas_solicitadas, p.fecha_solicitud, 
                           p.estado, p.documento, p.comentarios_empleado, p.comentarios_supervisor,
                           p.revisado_por, p.fecha_revisado
                    FROM Permisos p
                    INNER JOIN TiposPermisos tp ON p.id_tipo_permiso = tp.id_tipo_permiso
                    INNER JOIN Empleados e ON p.id_empleado = e.id_empleado
                    WHERE p.estado IN ('aprobado','rechazado')
                    ORDER BY p.fecha_solicitud DESC";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    SqlDataReader reader = cmd.ExecuteReader();
                    repeaterHistorial.DataSource = reader;
                    repeaterHistorial.DataBind();
                }
            }
        }
        */
        private void InsertarNotificacion(int idEmpleado, string mensaje, string tipo)
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "INSERT INTO Notificaciones (id_empleado, mensaje, tipo, fecha_creacion, leido) VALUES (@id_empleado, @mensaje, @tipo, GETDATE(), 0)";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id_empleado", idEmpleado);
                    cmd.Parameters.AddWithValue("@mensaje", mensaje);
                    cmd.Parameters.AddWithValue("@tipo", tipo);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        public string GetStatusColor(string estado)
        {
            switch (estado.ToLower())
            {
                case "pendiente":
                    return "#fff3cd"; // amarillo claro
                case "aprobado":
                    return "#d4edda"; // verde claro
                case "rechazado":
                    return "#f8d7da"; // rojo claro
                default:
                    return "#ffffff";
            }
        }

        public bool IsAdmin()
        {
            return Session["rol"] != null && Session["rol"].ToString().ToLower() == "admin";
        }

        protected void Aprobar_Click(object sender, EventArgs e)
        {
            int idPermiso = Convert.ToInt32(((LinkButton)sender).CommandArgument);
            TextBox txtComentario = (TextBox)((LinkButton)sender).Parent.FindControl("txtComentariosSupervisor");
            string comentario = txtComentario != null ? txtComentario.Text.Trim() : "";
            string usuarioRevisor = Session["username"].ToString();
            DateTime fechaRevision = DateTime.Now;
            int idEmpleadoSolicitante = 0;

            //Obtener el id del empleado solicitante para la notificación
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "SELECT id_empleado FROM Permisos WHERE id_permiso = @id_permiso";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id_permiso", idPermiso);
                    object result = cmd.ExecuteScalar();
                    if (result != null && result != DBNull.Value)
                    {
                        idEmpleadoSolicitante = Convert.ToInt32(result);
                    }
                }
            }


            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string update = @"UPDATE Permisos 
                                  SET estado = 'aprobado', 
                                      comentarios_supervisor = @comentario, 
                                      revisado_por = @usuarioRevisor,
                                      fecha_revisado = @fechaRevision
                                  WHERE id_permiso = @id_permiso";
                using (SqlCommand cmd = new SqlCommand(update, conn))
                {
                    cmd.Parameters.AddWithValue("@comentario", comentario);
                    cmd.Parameters.AddWithValue("@usuarioRevisor", usuarioRevisor);
                    cmd.Parameters.AddWithValue("@fechaRevision", fechaRevision);
                    cmd.Parameters.AddWithValue("@id_permiso", idPermiso);
                    cmd.ExecuteNonQuery();
                }
            }

            //Insertar notificación para el empleado solicitante
            if (idEmpleadoSolicitante > 0)
            {
                InsertarNotificacion(idEmpleadoSolicitante, "Permiso Aprobado", "PermisoAprobado");
            }

            CargarPermisosPendientes();
            CargarHistorial();
        }

        protected void Rechazar_Click(object sender, EventArgs e)
        {
            int idPermiso = Convert.ToInt32(((LinkButton)sender).CommandArgument);
            TextBox txtComentario = (TextBox)((LinkButton)sender).Parent.FindControl("txtComentariosSupervisor");
            string comentario = txtComentario != null ? txtComentario.Text.Trim() : "";
            string usuarioRevisor = Session["username"].ToString();
            DateTime fechaRevision = DateTime.Now;
            double horasSolicitadas = 0;
            int idTipoPermiso = 0;
            int idEmpleadoSolicitante = 0;

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "SELECT id_tipo_permiso, id_empleado, horas_solicitadas FROM Permisos WHERE id_permiso = @id_permiso";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id_permiso", idPermiso);
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            idTipoPermiso = Convert.ToInt32(reader["id_tipo_permiso"]);
                            idEmpleadoSolicitante = Convert.ToInt32(reader["id_empleado"]);
                            horasSolicitadas = Convert.ToDouble(reader["horas_solicitadas"]);
                        }
                    }
                }
                //Devolver saldo: sumar las horas solicitadas al saldo actual
                string updateSaldo = "UPDATE SaldoPermisos SET horas_disponibles = horas_disponibles + @horasSolicitadas " +
                                     "WHERE id_empleado = @id_empleado AND id_tipo_permiso = @id_tipo_permiso";
                using (SqlCommand cmd = new SqlCommand(updateSaldo, conn))
                {
                    cmd.Parameters.AddWithValue("@horasSolicitadas", horasSolicitadas);
                    cmd.Parameters.AddWithValue("@id_empleado", idEmpleadoSolicitante);
                    cmd.Parameters.AddWithValue("@id_tipo_permiso", idTipoPermiso);
                    cmd.ExecuteNonQuery();
                }
                //Actualizar el permiso como rechazado
                string updatePermiso = @"UPDATE Permisos 
                                         SET estado = 'rechazado', 
                                             comentarios_supervisor = @comentario, 
                                             revisado_por = @usuarioRevisor,
                                             fecha_revisado = @fechaRevision
                                         WHERE id_permiso = @id_permiso";
                using (SqlCommand cmd = new SqlCommand(updatePermiso, conn))
                {
                    cmd.Parameters.AddWithValue("@comentario", comentario);
                    cmd.Parameters.AddWithValue("@usuarioRevisor", usuarioRevisor);
                    cmd.Parameters.AddWithValue("@fechaRevision", fechaRevision);
                    cmd.Parameters.AddWithValue("@id_permiso", idPermiso);
                    cmd.ExecuteNonQuery();
                }
            }
            //Insertar notificación para el empleado solicitante con el mensaje "Permiso Rechazado"
            if (idEmpleadoSolicitante > 0)
            {
                InsertarNotificacion(idEmpleadoSolicitante, "Permiso Rechazado", "PermisoRechazado");
            }
            CargarPermisosPendientes();
            CargarHistorial();
        }

        protected void Eliminar_Click(object sender, EventArgs e)
        {
            int idPermiso = Convert.ToInt32(((LinkButton)sender).CommandArgument);
            double horasSolicitadas = 0;
            int idTipoPermiso = 0;
            int idEmpleadoSolicitante = 0;
            string estado = "";

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                //recuperar la información del permiso a eliminar
                string query = "SELECT id_tipo_permiso, id_empleado, horas_solicitadas, estado FROM Permisos WHERE id_permiso = @id_permiso";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id_permiso", idPermiso);
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            idTipoPermiso = Convert.ToInt32(reader["id_tipo_permiso"]);
                            idEmpleadoSolicitante = Convert.ToInt32(reader["id_empleado"]);
                            horasSolicitadas = Convert.ToDouble(reader["horas_solicitadas"]);
                            estado = reader["estado"].ToString();
                        }
                    }
                }

                //Si el permiso está pendiente, devolver el saldo al empleado
                if (estado.ToLower() == "pendiente")
                {
                    string updateSaldo = @"
                UPDATE SaldoPermisos 
                SET horas_disponibles = horas_disponibles + @horasSolicitadas 
                WHERE id_empleado = @id_empleado AND id_tipo_permiso = @id_tipo_permiso";
                    using (SqlCommand cmd = new SqlCommand(updateSaldo, conn))
                    {
                        cmd.Parameters.AddWithValue("@horasSolicitadas", horasSolicitadas);
                        cmd.Parameters.AddWithValue("@id_empleado", idEmpleadoSolicitante);
                        cmd.Parameters.AddWithValue("@id_tipo_permiso", idTipoPermiso);
                        cmd.ExecuteNonQuery();
                    }
                }

                //Eliminar el registro del permiso
                string delete = "DELETE FROM Permisos WHERE id_permiso = @id_permiso";
                using (SqlCommand cmd = new SqlCommand(delete, conn))
                {
                    cmd.Parameters.AddWithValue("@id_permiso", idPermiso);
                    cmd.ExecuteNonQuery();
                }
            }
            CargarPermisosPendientes();
            CargarHistorial();
        }

        protected void btnFiltrar_Click(object sender, EventArgs e)
        {
            CargarHistorial();
        }

        protected void EliminarPermisoHistorial_Click(object sender, EventArgs e)
        {
            int idPermiso = Convert.ToInt32(((LinkButton)sender).CommandArgument);
            double horasSolicitadas = 0;
            int idTipoPermiso = 0;
            int idEmpleadoSolicitante = 0;
            string estado = "";

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                //Recuperar datos del permiso a eliminar
                string query = "SELECT id_tipo_permiso, id_empleado, horas_solicitadas, estado FROM Permisos WHERE id_permiso = @id_permiso";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id_permiso", idPermiso);
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            idTipoPermiso = Convert.ToInt32(reader["id_tipo_permiso"]);
                            idEmpleadoSolicitante = Convert.ToInt32(reader["id_empleado"]);
                            horasSolicitadas = Convert.ToDouble(reader["horas_solicitadas"]);
                            estado = reader["estado"].ToString();
                        }
                    }
                }

                //Si el permiso estaba aprobado, devolver el saldo (horas)
                if (estado.ToLower() == "aprobado")
                {
                    string updateSaldo = @"
                UPDATE SaldoPermisos 
                SET horas_disponibles = horas_disponibles + @horasSolicitadas 
                WHERE id_empleado = @id_empleado AND id_tipo_permiso = @id_tipo_permiso";
                    using (SqlCommand cmd = new SqlCommand(updateSaldo, conn))
                    {
                        cmd.Parameters.AddWithValue("@horasSolicitadas", horasSolicitadas);
                        cmd.Parameters.AddWithValue("@id_empleado", idEmpleadoSolicitante);
                        cmd.Parameters.AddWithValue("@id_tipo_permiso", idTipoPermiso);
                        cmd.ExecuteNonQuery();
                    }
                }

                //Eliminar el registro del permiso
                string delete = "DELETE FROM Permisos WHERE id_permiso = @id_permiso";
                using (SqlCommand cmd = new SqlCommand(delete, conn))
                {
                    cmd.Parameters.AddWithValue("@id_permiso", idPermiso);
                    cmd.ExecuteNonQuery();
                }
            }
            CargarPermisosPendientes();
            CargarHistorial();
        }

    }
}
