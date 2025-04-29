using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Sistema_RRHH.Clases;

namespace Sistema_RRHH
{
	public partial class ActualizarDatos : System.Web.UI.Page
	{
        string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;
        protected void Page_Load(object sender, EventArgs e)
		{

            if (Session["username"] == null || Session["id_empleado"] == null || Session["id_usuario"] == null)
            {
                Response.Redirect("Login.aspx");
            }
            if (!IsPostBack)
            {
                CargarDatos();
                CargarPreguntasSeguridad();
            }
        }

        private void CargarDatos()
        {
            int idEmpleado = Convert.ToInt32(Session["id_empleado"]);
            int idUsuario = Convert.ToInt32(Session["id_usuario"]);
            string rol = Session["rol"]?.ToString().ToLower() ?? "";
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                //consulta para obtener datos del empleado y del usuario
                string query = @"
                    SELECT e.codigo_empleado, e.nombre, e.apellido, e.fecha_nacimiento, e.genero, e.direccion, 
                   e.telefono, e.correo, e.cargo, d.nombre AS Departamento, u.username, u.id_pregunta_seguridad
                    FROM Empleados e
                    INNER JOIN Usuarios u ON e.id_usuario = u.id_usuario
                    LEFT JOIN Departamentos d ON e.id_departamento = d.id_departamento
                    WHERE e.id_empleado = @id_empleado AND u.id_usuario = @id_usuario";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id_empleado", idEmpleado);
                    cmd.Parameters.AddWithValue("@id_usuario", idUsuario);
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            //asignar valores a los controles
                            txtTelefono.Text = reader["telefono"].ToString();
                            txtDireccion.Text = reader["direccion"].ToString();
                            ddlGenero.SelectedValue = reader["genero"] != DBNull.Value ? reader["genero"].ToString() : "";
                            txtFechaNacimiento.Text = reader["fecha_nacimiento"] != DBNull.Value ? Convert.ToDateTime(reader["fecha_nacimiento"]).ToString("yyyy-MM-dd") : "";
                            //La contraseña no se muestra por seguridad

                            //literales superiores
                            litNombreCompleto.Text = reader["nombre"] + " " + reader["apellido"];
                            litDepartamento.Text = reader["Departamento"].ToString();
                            litCargo.Text = reader["cargo"].ToString();

                            //actualizar el DropDownList de Preguntas de Seguridad
                            if (reader["id_pregunta_seguridad"] != DBNull.Value)
                            {
                                string idPregunta = reader["id_pregunta_seguridad"].ToString();
                                //si el valor no es "0", asignarlo
                                if (!string.IsNullOrEmpty(idPregunta) && idPregunta != "0")
                                {
                                    ddlPreguntaSeguridad.SelectedValue = idPregunta;
                                }
                            }

                            var datos = new
                            {
                                codigo_empleado = reader["codigo_empleado"],
                                nombre = reader["nombre"],
                                apellido = reader["apellido"],
                                fecha_nacimiento = reader["fecha_nacimiento"],
                                genero = reader["genero"],
                                direccion = reader["direccion"],
                                telefono = reader["telefono"],
                                correo = reader["correo"],
                                cargo = reader["cargo"],
                                departamento = reader["Departamento"],
                                username = reader["username"]
                            };
                            repeaterDatos.DataSource = new[] { datos };
                            repeaterDatos.DataBind();
                        }
                    }
                }

                //si es supervisor, mostrar empleados bajo su cargo
                if (rol == "supervisor" || rol == "rh")
                {
                    panelSupervisados.Visible = true;
                    CargarSupervisados(idEmpleado);
                }
                else
                {
                    panelSupervisados.Visible = false;
                }

            }
        }

        private void CargarSupervisados(int idSupervisor)
        {
            var lista = new List<dynamic>();
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();

                //obtener el departamento del supervisor
                int idDepartamento = 0;
                using (var cmdDepto = new SqlCommand(
                    "SELECT id_departamento FROM Empleados WHERE id_empleado = @idSupervisor", conn))
                {
                    cmdDepto.Parameters.AddWithValue("@idSupervisor", idSupervisor);
                    var depto = cmdDepto.ExecuteScalar();
                    if (depto == null || depto == DBNull.Value)
                    {
                        //no tiene departamento, no hay supervisados
                        return;
                    }
                    idDepartamento = Convert.ToInt32(depto);
                }

                //traer empleados que estén en el mismo departamento
                using (var cmd = new SqlCommand(@"
            SELECT 
                e.codigo_empleado,
                (e.nombre + ' ' + e.apellido) AS nombreCompleto,
                e.cargo
            FROM Empleados e
            INNER JOIN Usuarios u 
                ON e.id_usuario = u.id_usuario
            WHERE e.id_departamento     = @idDepartamento
              AND e.id_empleado         <> @idSupervisor
              AND u.estado              = 'Activo'
            ORDER BY e.nombre, e.apellido", conn))
                {
                    cmd.Parameters.AddWithValue("@idDepartamento", idDepartamento);
                    cmd.Parameters.AddWithValue("@idSupervisor", idSupervisor);

                    using (var reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            lista.Add(new
                            {
                                codigo_empleado = reader["codigo_empleado"],
                                nombreCompleto = reader["nombreCompleto"],
                                cargo = reader["cargo"]
                            });
                        }
                    }
                }
            }

            rptSupervisados.DataSource = lista;
            rptSupervisados.DataBind();
        }

        protected void btnActualizar_Click(object sender, EventArgs e)
        {
            int idEmpleado = Convert.ToInt32(Session["id_empleado"]);
            int idUsuario = Convert.ToInt32(Session["id_usuario"]);

            string telefono = txtTelefono.Text.Trim();
            string direccion = txtDireccion.Text.Trim();
            string genero = ddlGenero.SelectedValue;
            DateTime? fechaNacimiento = null;
            if (DateTime.TryParse(txtFechaNacimiento.Text.Trim(), out DateTime fn))
            {
                fechaNacimiento = fn;
            }

            //si se ingreso una nueva contraseña, la hasheamos; si no, dejamos el valor actual
            string nuevaPassword = txtPassword.Text.Trim();
            string passwordHash = string.Empty;
            if (!string.IsNullOrEmpty(nuevaPassword))
            {
                passwordHash = Usuarios.HashPassword(nuevaPassword);
            }

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                //actualizamos los datos del empleado
                string queryEmpleado = @"
                    UPDATE Empleados
                    SET telefono = @telefono,
                        direccion = @direccion,
                        genero = @genero,
                        fecha_nacimiento = @fecha_nacimiento
                    WHERE id_empleado = @id_empleado";
                using (SqlCommand cmd = new SqlCommand(queryEmpleado, conn))
                {
                    cmd.Parameters.AddWithValue("@telefono", telefono);
                    cmd.Parameters.AddWithValue("@direccion", direccion);
                    cmd.Parameters.AddWithValue("@genero", string.IsNullOrEmpty(genero) ? (object)DBNull.Value : genero);
                    cmd.Parameters.AddWithValue("@fecha_nacimiento", fechaNacimiento.HasValue ? (object)fechaNacimiento.Value : DBNull.Value);
                    cmd.Parameters.AddWithValue("@id_empleado", idEmpleado);
                    cmd.ExecuteNonQuery();
                }
                //si se ingreso nueva contraseña, actualizar en la tabla Usuarios
                if (!string.IsNullOrEmpty(passwordHash))
                {
                    string queryUsuario = "UPDATE Usuarios SET password = @password WHERE id_usuario = @id_usuario";
                    using (SqlCommand cmd = new SqlCommand(queryUsuario, conn))
                    {
                        cmd.Parameters.AddWithValue("@password", passwordHash);
                        cmd.Parameters.AddWithValue("@id_usuario", idUsuario);
                        cmd.ExecuteNonQuery();
                    }
                }

                //actualizar la configuración de seguridad si se seleccionó una pregunta y se ingresó respuesta
                if (ddlPreguntaSeguridad.SelectedValue != "0" && !string.IsNullOrWhiteSpace(txtRespuestaSeguridad.Text))
                {
                    //hashear la respuesta usando el método HashPassword
                    string respuestaHash = Usuarios.HashPassword(txtRespuestaSeguridad.Text.Trim());
                    string querySeguridad = @"
                            UPDATE Usuarios
                            SET id_pregunta_seguridad = @id_pregunta_seguridad,
                                respuesta_seguridad = @respuesta_seguridad
                            WHERE id_usuario = @id_usuario";
                    using (SqlCommand cmd = new SqlCommand(querySeguridad, conn))
                    {
                        cmd.Parameters.AddWithValue("@id_pregunta_seguridad", Convert.ToInt32(ddlPreguntaSeguridad.SelectedValue));
                        cmd.Parameters.AddWithValue("@respuesta_seguridad", respuestaHash);
                        cmd.Parameters.AddWithValue("@id_usuario", idUsuario);
                        cmd.ExecuteNonQuery();
                    }
                }

            }

            litMensaje.Text = "<div class='alert alert-success'>Datos actualizados correctamente.</div>";
            //recargar los datos actualizados
            CargarDatos();
        }

        private void CargarPreguntasSeguridad()
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "SELECT id_pregunta_seguridad, pregunta FROM PreguntasSeguridad ORDER BY id_pregunta_seguridad";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    ddlPreguntaSeguridad.DataSource = cmd.ExecuteReader();
                    ddlPreguntaSeguridad.DataValueField = "id_pregunta_seguridad";
                    ddlPreguntaSeguridad.DataTextField = "pregunta";
                    ddlPreguntaSeguridad.DataBind();
                    ddlPreguntaSeguridad.Items.Insert(0, new ListItem("Seleccione una pregunta", "0"));
                }
            }
        }

    }
	
}