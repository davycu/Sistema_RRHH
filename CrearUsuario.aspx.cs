using Sistema_RRHH.Clases;
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

namespace Sistema_RRHH
{
    public partial class CrearUsuario : System.Web.UI.Page
    {
        string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {

            //Verificar el rol del usuario
            Seguridad.VerificarAdmin(this);

            if (!IsPostBack)
            {
                CargarUsuarios();
                CargarEmpleados();
            }
        }

        private void CargarEmpleados()
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                SqlCommand cmd = new SqlCommand("SELECT id_empleado, codigo_empleado, nombre, apellido FROM Empleados WHERE id_usuario IS NULL", conn);
                SqlDataReader reader = cmd.ExecuteReader();

                ddlEmpleado.Items.Clear();
                ddlEmpleado.Items.Add(new ListItem("Seleccione un empleado", "0"));
                while (reader.Read())
                {
                    string displayText = $"{reader["codigo_empleado"]} - {reader["nombre"]} {reader["apellido"]}";
                    ddlEmpleado.Items.Add(new ListItem(displayText, reader["id_empleado"].ToString()));
                }
            }
        }

        protected void btnGuardar_Click(object sender, EventArgs e)
        {
 
            litAlert.Text = "";

            //Validar que el nombre de usuario no esté vacío
            if (string.IsNullOrWhiteSpace(txtUsername.Text))
            {
                litAlert.Text = "<div class='alert alert-danger'>El nombre de usuario es obligatorio.</div>";
                return;
            }

            //Validar que la contraseña no esté vacía
            if (string.IsNullOrEmpty(hiddenUserId.Value) && string.IsNullOrWhiteSpace(txtPassword.Text))
            {
                litAlert.Text = "<div class='alert alert-danger'>La contraseña es obligatoria.</div>";
                return;
            }

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();

                //Validación para evitar username duplicados (sólo para nuevos usuarios)
                if (string.IsNullOrEmpty(hiddenUserId.Value))
                {
                    SqlCommand cmdCheck = new SqlCommand("SELECT COUNT(*) FROM Usuarios WHERE username = @username", conn);
                    cmdCheck.Parameters.AddWithValue("@username", txtUsername.Text.Trim());
                    int count = Convert.ToInt32(cmdCheck.ExecuteScalar());
                    if (count > 0)
                    {
                        litAlert.Text = "<div class='alert alert-danger'>El nombre de usuario ya existe. Por favor, elija otro.</div>";
                        return;
                    }
                }

                SqlCommand cmd;

                string hashedPassword = HashPassword(txtPassword.Text.Trim());
                int idEmpleado = ddlEmpleado.SelectedValue == "0" ? 0 : Convert.ToInt32(ddlEmpleado.SelectedValue);
                string estado = ddlEstado.SelectedValue;

                if (string.IsNullOrEmpty(hiddenUserId.Value)) // Nuevo usuario
                {
                    cmd = new SqlCommand("INSERT INTO Usuarios (username, password, rol, estado) VALUES (@username, @password, @rol, @estado); SELECT SCOPE_IDENTITY();", conn);
                    cmd.Parameters.AddWithValue("@password", hashedPassword);
                }
                else //Actualizar usuario existente
                {
                    //Si se ingresa una nueva contraseña, se actualiza; de lo contrario, no se actualiza.
                    if (!string.IsNullOrWhiteSpace(txtPassword.Text))
                    {
                        cmd = new SqlCommand("UPDATE Usuarios SET username=@username, password=@password, rol=@rol, estado=@estado WHERE id_usuario=@id_usuario; SELECT @id_usuario", conn);
                        cmd.Parameters.AddWithValue("@password", hashedPassword);
                    }
                    else
                    {
                        cmd = new SqlCommand("UPDATE Usuarios SET username=@username, rol=@rol, estado=@estado WHERE id_usuario=@id_usuario; SELECT @id_usuario", conn);
                    }
                    cmd.Parameters.AddWithValue("@id_usuario", hiddenUserId.Value);
                }

                cmd.Parameters.AddWithValue("@username", txtUsername.Text.Trim());

                //En el caso de inserción, el parámetro "@password" se debe agregar una sola vez, por lo que si no se ha agregado en
                //la rama de actualización, lo agregamos:
                if (cmd.CommandText.Contains("@password") && !cmd.Parameters.Contains("@password"))
                {
                    cmd.Parameters.AddWithValue("@password", hashedPassword);
                }

                cmd.Parameters.AddWithValue("@rol", ddlRol.SelectedValue);
                cmd.Parameters.AddWithValue("@estado", estado);

                int userId = Convert.ToInt32(cmd.ExecuteScalar());

                if (idEmpleado > 0)
                {
                    SqlCommand updateCmd = new SqlCommand("UPDATE Empleados SET id_usuario = @id_usuario WHERE id_empleado = @id_empleado", conn);
                    updateCmd.Parameters.AddWithValue("@id_usuario", userId);
                    updateCmd.Parameters.AddWithValue("@id_empleado", idEmpleado);
                    updateCmd.ExecuteNonQuery();
                }

                litAlert.Text = "<div class='alert alert-success'>Usuario guardado correctamente.</div>";

                CargarUsuarios();
                CargarEmpleados();
                LimpiarFormulario();
            }
        }

        protected void btnEditar_Click(object sender, EventArgs e)
        {

            //LIMPIAR litAlert al inicio
            litAlert.Text = "";

            Button btn = (Button)sender;
            string usuarioId = btn.CommandArgument;

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                SqlCommand cmd = new SqlCommand("SELECT * FROM Usuarios WHERE id_usuario=@id_usuario", conn);
                cmd.Parameters.AddWithValue("@id_usuario", usuarioId);
                SqlDataReader reader = cmd.ExecuteReader();

                if (reader.Read())
                {
                    hiddenUserId.Value = reader["id_usuario"].ToString();
                    txtUsername.Text = reader["username"].ToString();
                    ddlRol.SelectedValue = reader["rol"].ToString();
                    ddlEstado.SelectedValue = reader["estado"].ToString(); //Asegurar que el estado se edite
                }
                reader.Close();
            }
        }


        protected void btnEliminar_Click(object sender, EventArgs e)
        {

            litAlert.Text = "";

            Button btnEliminar = (Button)sender;
            string usuarioId = btnEliminar.CommandArgument;

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();

                //desasociar el usuario de los empleados
                SqlCommand updateCmd = new SqlCommand("UPDATE Empleados SET id_usuario = NULL WHERE id_usuario = @id_usuario", conn);
                updateCmd.Parameters.AddWithValue("@id_usuario", usuarioId);
                updateCmd.ExecuteNonQuery();

                //eliminar el usuario de la tabla Usuarios
                SqlCommand deleteCmd = new SqlCommand("DELETE FROM Usuarios WHERE id_usuario=@id_usuario", conn);
                deleteCmd.Parameters.AddWithValue("@id_usuario", usuarioId);
                deleteCmd.ExecuteNonQuery();

                litAlert.Text = "<div class='alert alert-success'>Usuario eliminado correctamente.</div>";
                CargarUsuarios();
                LimpiarFormulario();
                CargarEmpleados();
            }
        }

        private void CargarUsuarios()
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = @"
            SELECT 
                u.id_usuario, 
                u.codigo_usuario, 
                u.username, 
                u.rol, 
                u.estado,  
                COALESCE(e.nombre + ' ' + e.apellido, '') AS nombreCompleto
            FROM Usuarios u
            LEFT JOIN Empleados e ON u.id_usuario = e.id_usuario";

                SqlCommand cmd = new SqlCommand(query, conn);
                SqlDataReader reader = cmd.ExecuteReader();

                repeaterUsuarios.DataSource = reader;
                repeaterUsuarios.DataBind();
            }
        }

        private void LimpiarFormulario()
        {
            hiddenUserId.Value = string.Empty;
            txtUsername.Text = string.Empty;
            txtPassword.Text = string.Empty;
            ddlRol.SelectedIndex = 0;
            ddlEmpleado.SelectedIndex = 0;
            ddlEstado.SelectedIndex = 0;
        }

        protected void btnCancelar_Click(object sender, EventArgs e)
        {
            //LIMPIAR litAlert al inicio
            litAlert.Text = "";
            LimpiarFormulario();
        }

        private static string HashPassword(string password)
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
    }
}
