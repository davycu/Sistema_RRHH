using Sistema_RRHH.Clases;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Sistema_RRHH
{
    public partial class Login : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }

        [WebMethod(EnableSession = true)]
        public static object AutenticarUsuario(string username, string password)
        {
            Usuarios usuario = Usuarios.ValidarUsuario(username, password);

            if (usuario != null)
            {

                //Verificar si el estado es "Activo"
                if (usuario.Estado != "Activo")
                {
                    return new { CodigoError = -2, Mensaje = "Su cuenta está inactiva. Contacte al administrador." };
                }

                HttpContext.Current.Session["id_usuario"] = usuario.IdUsuario;
                HttpContext.Current.Session["username"] = usuario.Username;
                HttpContext.Current.Session["rol"] = usuario.Rol;
                

                //Obtener el nombre y apellido desde la tabla Empleados
                using (SqlConnection conn = new SqlConnection(ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString))
                {
                    conn.Open();
                    SqlCommand cmd = new SqlCommand(
                        "SELECT id_empleado, id_departamento, nombre, apellido, fecha_ingreso FROM Empleados WHERE id_usuario = @id_usuario", conn);
                    cmd.Parameters.AddWithValue("@id_usuario", usuario.IdUsuario);
                    SqlDataReader reader = cmd.ExecuteReader();

                    if (reader.Read())
                    {
                        int idEmpleado = Convert.ToInt32(reader["id_empleado"]);
                        HttpContext.Current.Session["id_empleado"] = idEmpleado;

                        //Obtener y almacenar el id_departamento
                        int idDepartamento = Convert.ToInt32(reader["id_departamento"]);
                        HttpContext.Current.Session["id_departamento"] = idDepartamento;

                        //obtener fecha ingreso
                        DateTime fechaIngreso = Convert.ToDateTime(reader["fecha_ingreso"]);
                        HttpContext.Current.Session["fecha_ingreso"] = fechaIngreso;

                        string nombreCompleto = reader["nombre"].ToString();
                        if (reader["apellido"] != DBNull.Value)
                        {
                            nombreCompleto += " " + reader["apellido"].ToString();
                        }
                        HttpContext.Current.Session["nombreCompleto"] = nombreCompleto; // Guardar en sesión
                    }
                    reader.Close();
                }

                string redireccion = "Inicio.aspx";

                return new { CodigoError = 1, Mensaje = "Inicio de sesión exitoso", Redireccion = redireccion };
            }
            else
            {
                return new { CodigoError = -1, Mensaje = "Usuario o contraseña incorrectos" };
            }
        }

        [WebMethod(EnableSession = true)]
        public static object CargarPreguntaSeguridad(string username, string email)
        {
            //Implementar un metodo para obtener el usuario segun username y email
            Usuarios usuario = Usuarios.ObtenerPorUsernameYEmail(username, email);
            if (usuario != null)
            {
                if (usuario.IdPreguntaSeguridad == null)
                {
                    return new { CodigoError = -2, Mensaje = "No se ha configurado la pregunta de seguridad. Actualice sus datos." };
                }
                else
                {
                    string pregunta = "";
                    using (SqlConnection conn = new SqlConnection(ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString))
                    {
                        conn.Open();
                        string query = "SELECT pregunta FROM PreguntasSeguridad WHERE id_pregunta_seguridad = @id";
                        using (SqlCommand cmd = new SqlCommand(query, conn))
                        {
                            cmd.Parameters.AddWithValue("@id", usuario.IdPreguntaSeguridad);
                            object result = cmd.ExecuteScalar();
                            if (result != null)
                                pregunta = result.ToString();
                        }
                    }
                    return new { CodigoError = 1, Pregunta = pregunta, Mensaje = "Pregunta cargada correctamente." };
                }
            }
            else
            {
                return new { CodigoError = -1, Mensaje = "Usuario o email incorrectos." };
            }
        }

        [WebMethod(EnableSession = true)]
        public static object RecuperarContrasenaConPregunta(string username, string email, string respuesta)
        {
            Usuarios usuario = Usuarios.ObtenerPorUsernameYEmail(username, email);
            if (usuario != null)
            {
                if (usuario.IdPreguntaSeguridad == null || string.IsNullOrEmpty(usuario.RespuestaSeguridad))
                {
                    return new { CodigoError = -2, Mensaje = "No se ha configurado la pregunta de seguridad. Contacte a soporte." };
                }
                //Verifica que la respuesta ingresada sea correcta (usar el metodo hash)
                bool correcta = Usuarios.VerificarRespuestaSeguridad(usuario.IdUsuario, respuesta);
                if (!correcta)
                {
                    return new { CodigoError = -1, Mensaje = "La respuesta es incorrecta." };
                }
                //Genera una contraseña temporal
                string contrasenaTemporal = GenerarContrasenaTemporal();
                Usuarios.ActualizarContrasena(usuario.IdUsuario, contrasenaTemporal);
                HttpContext.Current.Session["cambiarContrasena"] = true;
                return new { CodigoError = 1, Mensaje = "Su contraseña temporal es: " + contrasenaTemporal + ". Por favor, actualícela al ingresar." };
            }
            else
            {
                return new { CodigoError = -3, Mensaje = "Usuario o email incorrectos." };
            }
        }

        private static string GenerarContrasenaTemporal()
        {
            const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
            var random = new Random();
            return new string(Enumerable.Repeat(chars, 8)
              .Select(s => s[random.Next(s.Length)]).ToArray());
        }

    }
}