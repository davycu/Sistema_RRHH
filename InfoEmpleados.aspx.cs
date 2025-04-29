using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Sistema_RRHH.Clases;

namespace Sistema_RRHH
{
    public partial class InfoEmpleados : System.Web.UI.Page
    {
        string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {

            Seguridad.VerificarAdminRh(this);

            if (!IsPostBack)
            {
                CargarEmpleados();
                pnlEmpleadoInfo.Visible = false; // Se oculta el panel inicialmente
            }
        }

        //Cargar el listado de empleados en el dropdown
        private void CargarEmpleados()
        {
            DataTable dt = new DataTable();
            string query = @"
                SELECT e.id_empleado, (e.nombre + ' ' + e.apellido) AS NombreCompleto
                FROM Empleados e
                ORDER BY e.nombre, e.apellido";

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        da.Fill(dt);
                    }
                }
            }
            ddlEmpleados.DataSource = dt;
            ddlEmpleados.DataTextField = "NombreCompleto";
            ddlEmpleados.DataValueField = "id_empleado";
            ddlEmpleados.DataBind();
            ddlEmpleados.Items.Insert(0, new System.Web.UI.WebControls.ListItem("-- Seleccione un Empleado --", "0"));
        }

        //Evento que se dispara al seleccionar un empleado
        protected void ddlEmpleados_SelectedIndexChanged(object sender, EventArgs e)
        {
            int idEmpleado = Convert.ToInt32(ddlEmpleados.SelectedValue);
            if (idEmpleado > 0)
            {
                CargarInformacionEmpleado(idEmpleado);
                pnlEmpleadoInfo.Visible = true;
            }
            else
            {
                pnlEmpleadoInfo.Visible = false;
            }
        }

        //Carga la información detallada del empleado seleccionado
        private void CargarInformacionEmpleado(int idEmpleado)
        {
            string query = @"
        SELECT 
            e.codigo_empleado,
            e.nombre,
            e.apellido,
            e.direccion,
            e.telefono,
            e.genero,
            d.nombre AS Departamento,
            CASE
                -- Si el empleado es supervisor...
                WHEN e.id_supervisor_departamento IS NOT NULL THEN 
                    CASE 
                        -- Si su departamento es Recursos Humanos, no se muestra supervisor
                        WHEN LOWER(d.nombre) = 'recursos humanos' THEN ''
                        ELSE 
                            -- De lo contrario, se busca el supervisor de RH (primer usuario con rol 'rh')
                            (SELECT TOP 1 s.nombre + ' ' + s.apellido 
                             FROM Empleados s 
                             INNER JOIN Usuarios u2 ON s.id_usuario = u2.id_usuario
                             WHERE LOWER(u2.rol) = 'rh')
                    END
                ELSE 
                    -- Si el empleado no es supervisor, se muestra el supervisor asignado (si existe)
                    ISNULL(
                        (SELECT TOP 1 s.nombre + ' ' + s.apellido 
                         FROM Empleados s 
                         WHERE s.id_departamento = e.id_departamento 
                           AND s.id_supervisor_departamento IS NOT NULL),
                        'N/D'
                    )
            END AS Supervisor,
            e.fecha_ingreso,
            e.fecha_finalizacion,
            e.salario,
            u.username,
            u.Estado,
            e.cargo
        FROM Empleados e
        LEFT JOIN Departamentos d ON e.id_departamento = d.id_departamento
        LEFT JOIN Usuarios u ON e.id_usuario = u.id_usuario
        WHERE e.id_empleado = @idEmpleado";

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@idEmpleado", idEmpleado);
                    conn.Open();
                    using (SqlDataReader dr = cmd.ExecuteReader())
                    {
                        if (dr.Read())
                        {
                            lblCodigoEmpleado.Text = dr["codigo_empleado"].ToString();
                            lblNombreCompleto.Text = dr["nombre"].ToString() + " " + dr["apellido"].ToString();
                            lblDireccion.Text = dr["direccion"] != DBNull.Value ? dr["direccion"].ToString() : "N/D";
                            lblTelefono.Text = dr["telefono"] != DBNull.Value ? dr["telefono"].ToString() : "N/D";
                            lblGenero.Text = dr["genero"] != DBNull.Value ? dr["genero"].ToString() : "N/D";
                            lblDepartamento.Text = dr["Departamento"] != DBNull.Value ? dr["Departamento"].ToString() : "N/D";
                            lblSupervisor.Text = dr["Supervisor"].ToString();
                            lblFechaIngreso.Text = Convert.ToDateTime(dr["fecha_ingreso"]).ToString("dd/MM/yyyy");
                            lblFechaFinalizacion.Text = dr["fecha_finalizacion"] != DBNull.Value ? Convert.ToDateTime(dr["fecha_finalizacion"]).ToString("dd/MM/yyyy") : "Activo";
                            lblSalario.Text = "L " + Convert.ToDecimal(dr["salario"]).ToString("N2");
                            lblUsuario.Text = dr["username"].ToString();
                            lblEstado.Text = dr["Estado"].ToString();
                            lblCargo.Text = dr["cargo"].ToString();
                        }
                    }
                }
            }
        }
    }
}