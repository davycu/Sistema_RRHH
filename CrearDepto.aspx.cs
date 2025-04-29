using Sistema_RRHH.Clases;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Sistema_RRHH
{
    public partial class CrearDepto : System.Web.UI.Page
    {
        string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {

            //Verificar el rol del usuario
            Seguridad.VerificarAdminRh(this);

            if (!IsPostBack)
            {
                CargarDepartamentos();
                CargarSupervisores();
            }
        }

        private void CargarSupervisores()
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                SqlCommand cmd = new SqlCommand("SELECT id_empleado, codigo_empleado, nombre, apellido FROM Empleados WHERE id_departamento IS NULL AND TipoEmpleado = 'Interno'", conn);
                SqlDataReader reader = cmd.ExecuteReader();

                ddlSupervisor.Items.Clear();
                ddlSupervisor.Items.Add(new ListItem("Seleccione un supervisor", "0"));
                while (reader.Read())
                {
                    string displayText = $"{reader["codigo_empleado"]} - {reader["nombre"]} {reader["apellido"]}";
                    ddlSupervisor.Items.Add(new ListItem(displayText, reader["id_empleado"].ToString()));
                }
            }
        }

        protected void btnGuardar_Click(object sender, EventArgs e)
        {

            // LIMPIAR litAlert al inicio
            litAlert.Text = "";

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                SqlCommand cmd;

                //Validar que el nombre del departamento no esté vacío
                if (string.IsNullOrWhiteSpace(txtNombreDepto.Text))
                {
                    litAlert.Text = "<div class='alert alert-danger'>El nombre del departamento es obligatorio.</div>";
                    return;
                }

                //Validar que no exista otro departamento con el mismo nombre
                SqlCommand checkDeptoCmd = new SqlCommand("SELECT COUNT(*) FROM Departamentos WHERE nombre = @nombre", conn);
                checkDeptoCmd.Parameters.AddWithValue("@nombre", txtNombreDepto.Text.Trim());

                int count = (int)checkDeptoCmd.ExecuteScalar();
                if (count > 0)
                {
                    litAlert.Text = "<div class='alert alert-danger'>El departamento ya existe.</div>";
                    return;
                }

                int idSupervisor = ddlSupervisor.SelectedValue == "0" ? 0 : Convert.ToInt32(ddlSupervisor.SelectedValue);

                if (string.IsNullOrEmpty(hiddenDeptId.Value)) //Nuevo departamento
                {
                    cmd = new SqlCommand("INSERT INTO Departamentos (nombre) VALUES (@nombre); SELECT SCOPE_IDENTITY();", conn);
                }
                else //Actualizar departamento
                {
                    cmd = new SqlCommand("UPDATE Departamentos SET nombre=@nombre WHERE id_departamento=@id_departamento", conn);
                    cmd.Parameters.AddWithValue("@id_departamento", hiddenDeptId.Value);
                }

                cmd.Parameters.AddWithValue("@nombre", txtNombreDepto.Text.Trim());

                int deptId = Convert.ToInt32(cmd.ExecuteScalar());

                if (idSupervisor > 0)
                {
                    SqlCommand updateCmd = new SqlCommand("UPDATE Empleados SET id_departamento = @id_departamento WHERE id_empleado = @id_supervisor", conn);
                    updateCmd.Parameters.AddWithValue("@id_departamento", deptId);
                    updateCmd.Parameters.AddWithValue("@id_supervisor", idSupervisor);
                    updateCmd.ExecuteNonQuery();
                }

                litAlert.Text = "<div class='alert alert-success'>Departamento guardado correctamente.</div>";

                CargarDepartamentos();
                CargarSupervisores();
                LimpiarFormulario();
            }
        }

        private void LimpiarFormulario()
        {
            hiddenDeptId.Value = string.Empty;
            txtNombreDepto.Text = string.Empty;
            ddlSupervisor.SelectedIndex = 0;
        }


        protected void btnEditar_Click(object sender, EventArgs e)
        {

            //LIMPIAR litAlert al inicio
            litAlert.Text = "";

            Button btn = (Button)sender;
            string deptId = btn.CommandArgument;

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                SqlCommand cmd = new SqlCommand("SELECT * FROM Departamentos WHERE id_departamento=@id_departamento", conn);
                cmd.Parameters.AddWithValue("@id_departamento", deptId);
                SqlDataReader reader = cmd.ExecuteReader();

                if (reader.Read())
                {
                    hiddenDeptId.Value = reader["id_departamento"].ToString();
                    txtNombreDepto.Text = reader["nombre"].ToString();
                }
                reader.Close();
            }
        }

        protected void btnEliminar_Click(object sender, EventArgs e)
        {

            litAlert.Text = "";

            //Verificar el rol del usuario desde la sesión.
            string rolUsuario = Session["rol"] != null ? Session["rol"].ToString().ToLower() : "";
            if (rolUsuario != "admin")
            {
                litAlert.Text = "<div class='alert alert-danger'>No tiene permisos para eliminar este registro.</div>";
                return;
            }

            Button btnEliminar = (Button)sender;
            string deptId = btnEliminar.CommandArgument;

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                SqlCommand cmd = new SqlCommand("DELETE FROM Departamentos WHERE id_departamento=@id_departamento", conn);
                cmd.Parameters.AddWithValue("@id_departamento", deptId);
                cmd.ExecuteNonQuery();

                litAlert.Text = "<div class='alert alert-success'>Departamento eliminado correctamente.</div>";
                CargarDepartamentos();
                CargarSupervisores();
            }
        }

        private void CargarDepartamentos()
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = @"
            SELECT 
                d.id_departamento, 
                d.codigo_departamento, 
                d.nombre AS nombre_departamento, 
                COALESCE(e.nombre + ' ' + e.apellido, 'No asignado') AS supervisor
            FROM Departamentos d
            LEFT JOIN Empleados e ON d.id_departamento = e.id_departamento 
            AND e.id_supervisor_departamento IS NOT NULL";

                SqlCommand cmd = new SqlCommand(query, conn);
                SqlDataReader reader = cmd.ExecuteReader();

                repeaterDepartamentos.DataSource = reader;
                repeaterDepartamentos.DataBind();
            }
        }

        protected void ocultarBtnEliminar(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                Button btnEliminar = (Button)e.Item.FindControl("btnEliminar");
                if (btnEliminar != null)
                {
                    string rolUsuario = Session["rol"] != null ? Session["rol"].ToString().ToLower() : "";
                    if (rolUsuario != "admin")
                    {
                        btnEliminar.Visible = false;
                    }
                }
            }
        }

        protected void btnCancelar_Click(object sender, EventArgs e)
        {
            //LIMPIAR litAlert al inicio
            litAlert.Text = "";
            LimpiarFormulario();
        }


    }
}