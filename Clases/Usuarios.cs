using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Web;

namespace Sistema_RRHH.Clases
{
    public class Usuarios
    {
        public int IdUsuario { get; set; }
        public string Username { get; set; }
        public string Password { get; set; }
        public string Rol { get; set; }
        public string Estado { get; set; }

        public int? IdPreguntaSeguridad { get; set; }
        public string RespuestaSeguridad { get; set; }

        //metodo para validar usuario y contraseña
        public static Usuarios ValidarUsuario(string username, string password)
        {
            Usuarios usuario = null;
            string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;

            string hashedPassword = HashPassword(password);

            using (SqlConnection connection = new SqlConnection(connectionString))
            {
                string query = "SELECT id_usuario, username, rol, estado FROM Usuarios WHERE username = @Username AND password = @Password";

                using (SqlCommand command = new SqlCommand(query, connection))
                {
                    command.Parameters.AddWithValue("@Username", username);
                    command.Parameters.AddWithValue("@Password", hashedPassword);

                    connection.Open();
                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            usuario = new Usuarios
                            {
                                IdUsuario = Convert.ToInt32(reader["id_usuario"]),
                                Username = reader["username"].ToString(),
                                Rol = reader["rol"].ToString(),
                                Estado = reader["estado"].ToString()
                            };
                        }
                    }
                }
            }
            return usuario;
        }

        //metodo para encriptar contraseña con SHA-256
        public static string HashPassword(string password)
        {
            using (SHA256 sha256 = SHA256.Create())
            {
                byte[] hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
                StringBuilder sb = new StringBuilder();
                foreach (byte b in hashedBytes)
                {
                    sb.Append(b.ToString("x2"));
                }
                return sb.ToString();
            }
        }

        //metodo para obtener el usuario por username y email
        public static Usuarios ObtenerPorUsernameYEmail(string username, string email)
        {
            Usuarios usuario = null;
            string connStr = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string query = @"
                    SELECT u.id_usuario, u.username, u.password, u.rol, u.Estado, u.id_pregunta_seguridad, u.respuesta_seguridad
                    FROM Usuarios u
                    INNER JOIN Empleados e ON u.id_usuario = e.id_usuario
                    WHERE u.username = @username AND e.correo = @email";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@username", username);
                    cmd.Parameters.AddWithValue("@email", email);
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            usuario = new Usuarios();
                            usuario.IdUsuario = Convert.ToInt32(reader["id_usuario"]);
                            usuario.Username = reader["username"].ToString();
                            usuario.Password = reader["password"].ToString();
                            usuario.Rol = reader["rol"].ToString();
                            usuario.Estado = reader["Estado"].ToString();
                            usuario.IdPreguntaSeguridad = reader["id_pregunta_seguridad"] != DBNull.Value
                                ? (int?)Convert.ToInt32(reader["id_pregunta_seguridad"])
                                : null;
                            usuario.RespuestaSeguridad = reader["respuesta_seguridad"] != DBNull.Value
                                ? reader["respuesta_seguridad"].ToString()
                                : null;
                        }
                    }
                }
            }
            return usuario;
        }

        //metodo para verificar la respuesta de seguridad ingresada (comparando el hash)
        public static bool VerificarRespuestaSeguridad(int idUsuario, string respuestaIngresada)
        {
            //obtiene el usuario para verificar la respuesta
            Usuarios usuario = null;
            string connStr = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string query = "SELECT respuesta_seguridad FROM Usuarios WHERE id_usuario = @idUsuario";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@idUsuario", idUsuario);
                    object result = cmd.ExecuteScalar();
                    if (result != null && result != DBNull.Value)
                    {
                        usuario = new Usuarios();
                        usuario.RespuestaSeguridad = result.ToString();
                    }
                }
            }
            if (usuario == null || string.IsNullOrEmpty(usuario.RespuestaSeguridad))
                return false;

            //Compara la respuesta ingresada hasheada con la almacenada
            string respuestaHash = HashPassword(respuestaIngresada);
            return string.Equals(respuestaHash, usuario.RespuestaSeguridad, StringComparison.OrdinalIgnoreCase);
        }

        //metodo para actualizar la contraseña del usuario
        public static void ActualizarContrasena(int idUsuario, string nuevaContrasena)
        {
            string connStr = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string query = "UPDATE Usuarios SET password = @password WHERE id_usuario = @idUsuario";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@password", HashPassword(nuevaContrasena));
                    cmd.Parameters.AddWithValue("@idUsuario", idUsuario);
                    cmd.ExecuteNonQuery();
                }
            }
        }

    }
}