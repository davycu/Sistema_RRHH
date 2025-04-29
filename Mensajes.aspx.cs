using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Diagnostics.Contracts;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.Services.Description;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;
using Sistema_RRHH.Clases;

namespace Sistema_RRHH
{
    public partial class Mensajes : System.Web.UI.Page
    {
        string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;
        protected void Page_Load(object sender, EventArgs e)
        {

            if (Session["username"] == null)
            {
                Response.Redirect("Login.aspx");
            }
            if (!IsPostBack)
            {
                CargarContactos();
            }
        }

        //pasar el id del usuario actual para realizar la consulta de los mensajes enviados
        private void CargarContactos()
        {
            int idUsuarioActual = Convert.ToInt32(Session["id_usuario"]);
            List<Contacto> contactos = new List<Contacto>();
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = @"
            SELECT u.id_usuario, e.nombre, e.apellido, e.cargo, d.nombre as departamento
            FROM Usuarios u
            INNER JOIN Empleados e ON u.id_usuario = e.id_usuario
            LEFT JOIN Departamentos d ON e.id_departamento = d.id_departamento
            WHERE u.id_usuario <> @id_usuario
            ORDER BY e.nombre, e.apellido";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id_usuario", idUsuarioActual);
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            int idContacto = Convert.ToInt32(reader["id_usuario"]);
                            contactos.Add(new Contacto
                            {
                                id_usuario = idContacto,
                                nombre = reader["nombre"].ToString(),
                                apellido = reader["apellido"].ToString(),
                                cargo = reader["cargo"].ToString(),
                                departamento = reader["departamento"]?.ToString() ?? "",
                                tieneMensajesNuevos = TieneMensajesNuevos(idContacto, idUsuarioActual)
                            });
                        }
                    }
                }
            }
            //Ordenar: primero los contactos con mensajes nuevos y luego por nombre
            contactos = contactos.OrderByDescending(c => c.tieneMensajesNuevos)
                                 .ThenBy(c => c.nombre)
                                 .ThenBy(c => c.apellido)
                                 .ToList();
            repeaterContactos.DataSource = contactos;
            repeaterContactos.DataBind();
        }

        //comprobar los mensajes enviados por el contacto al usuario actual
        //(donde el contacto es el emisor y el usuario actual es el receptor)
        private bool TieneMensajesNuevos(int idContacto, int idUsuarioActual)
        {
            bool tiene = false;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "SELECT COUNT(*) FROM Mensajes WHERE id_emisor = @idContacto AND id_receptor = @idUsuarioActual AND leido = 0";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@idContacto", idContacto);
                    cmd.Parameters.AddWithValue("@idUsuarioActual", idUsuarioActual);
                    int count = Convert.ToInt32(cmd.ExecuteScalar());
                    tiene = count > 0;
                }
            }
            return tiene;
        }


        [WebMethod(EnableSession = true)]
        public static string ObtenerMensajes(int idReceptor)
        {
            int idEmisor = Convert.ToInt32(System.Web.HttpContext.Current.Session["id_usuario"]);
            List<Mensaje> mensajes = new List<Mensaje>();
            string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = @"
                    SELECT m.mensaje, m.fecha_envio, u.username as emisor
                    FROM Mensajes m
                    INNER JOIN Usuarios u ON m.id_emisor = u.id_usuario
                    WHERE (m.id_emisor = @id_emisor AND m.id_receptor = @idReceptor)
                       OR (m.id_emisor = @idReceptor AND m.id_receptor = @id_emisor)
                    ORDER BY m.fecha_envio ASC";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id_emisor", idEmisor);
                    cmd.Parameters.AddWithValue("@idReceptor", idReceptor);
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            mensajes.Add(new Mensaje
                            {
                                mensaje = reader["mensaje"].ToString(),
                                fecha_envio = Convert.ToDateTime(reader["fecha_envio"]),
                                emisor = reader["emisor"].ToString()
                            });
                        }
                    }
                }
            }
            //Construir el HTML para los mensajes
            StringBuilder sb = new StringBuilder();
            //obtener el nombre del usuario actual para compararlo
            string usuarioActual = HttpContext.Current.Session["username"].ToString();
            foreach (var m in mensajes)
            {
                //Si el emisor es el usuario actual, se aplica 'sent', de lo contrario 'received'
                string clase = m.emisor.Equals(usuarioActual, StringComparison.OrdinalIgnoreCase)
                               ? "message sent"
                               : "message received";
                sb.AppendFormat("<div class='{0} mb-2'><strong>{1}:</strong> {2} <small class='text-muted'>{3:yyyy-MM-dd HH:mm}</small></div>",
                    clase, m.emisor, m.mensaje, m.fecha_envio);
            }
            return sb.ToString();
        }

        [WebMethod(EnableSession = true)]
        public static object EnviarMensaje(int idReceptor, string mensaje)
        {
            int idEmisor = Convert.ToInt32(System.Web.HttpContext.Current.Session["id_usuario"]);
            string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string insert = @"
                    INSERT INTO Mensajes (id_emisor, id_receptor, mensaje)
                    VALUES (@id_emisor, @id_receptor, @mensaje)";
                using (SqlCommand cmd = new SqlCommand(insert, conn))
                {
                    cmd.Parameters.AddWithValue("@id_emisor", idEmisor);
                    cmd.Parameters.AddWithValue("@id_receptor", idReceptor);
                    cmd.Parameters.AddWithValue("@mensaje", mensaje);
                    cmd.ExecuteNonQuery();
                }
            }
            return new { success = true };
        }

        //metodo estatico para actualizar mensajes de un contacto cuando se abre a leido
        [WebMethod(EnableSession = true)]
        public static void MarcarMensajesComoLeidos(int idReceptor)
        {
            int idUsuario = Convert.ToInt32(HttpContext.Current.Session["id_usuario"]);
            string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                // actualizamos los mensajes enviados por el contacto (idReceptor) al usuario actual
                // que aún no han sido leídos.
                string update = "UPDATE Mensajes SET leido = 1 WHERE id_emisor = @idReceptor AND id_receptor = @idUsuario AND leido = 0";
                using (SqlCommand cmd = new SqlCommand(update, conn))
                {
                    cmd.Parameters.AddWithValue("@idReceptor", idReceptor);
                    cmd.Parameters.AddWithValue("@idUsuario", idUsuario);
                    cmd.ExecuteNonQuery();
                }

            }

        }

        [WebMethod(EnableSession = true)]
        public static int ObtenerConteoMensajesNuevos()
        {
            int idUsuario = Convert.ToInt32(HttpContext.Current.Session["id_usuario"]);
            int count = 0;
            string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                
                // Contar los mensajes no leídos dirigidos al usuario actual
                //string query = "SELECT COUNT(*) FROM Mensajes WHERE id_receptor = @id_usuario AND leido = 0";
                
                // Se cuenta solo cada remitente único que tenga mensajes sin leer
                string query = "SELECT COUNT(DISTINCT id_emisor) FROM Mensajes WHERE id_receptor = @id_usuario AND leido = 0";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id_usuario", idUsuario);
                    count = Convert.ToInt32(cmd.ExecuteScalar());
                }
            }
            return count;
        }


    }

}
    
