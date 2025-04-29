using Sistema_RRHH.Clases;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Sistema_RRHH
{
	public partial class ReportePermisos : System.Web.UI.Page
	{
        string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
		{
            Seguridad.VerificarAdminRh(this);
            if (!IsPostBack)
            {
                CargarEmpleados();
            }

        }

        private void CargarEmpleados()
        {
            DataTable dt = new DataTable();
            string query = @"
                SELECT e.id_empleado, (e.nombre + ' ' + e.apellido) AS NombreCompleto
                FROM Empleados e
                INNER JOIN Usuarios u ON e.id_usuario = u.id_usuario
                WHERE u.Estado = 'Activo'
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

        protected void ddlEmpleados_SelectedIndexChanged(object sender, EventArgs e)
        {
            int idEmpleado = 0;
            if (int.TryParse(ddlEmpleados.SelectedValue, out idEmpleado) && idEmpleado > 0)
            {
                CargarReporteEmpleado(idEmpleado);
                infoEmpleado.Visible = true;
            }
            else
            {
                infoEmpleado.Visible = false;
            }
        }

        private void CargarReporteEmpleado(int idEmpleado)
        {
            DataTable dt = new DataTable();
            //La consulta genera una fila por cada tipo de permiso.
            //Si el empleado ya tiene un registro en SaldoPermisos, se usa ese valor; de lo contrario, se usa el valor base de TiposPermisos.
            string query = @"
                SELECT 
                    tp.nombre_permiso,
                    ISNULL(CAST(sp.horas_disponibles AS FLOAT), tp.dias_maximos_anuales * 8.0) AS HorasDisponibles,
                    ISNULL(CAST(sp.horas_disponibles AS FLOAT) / 8.0, tp.dias_maximos_anuales) AS DiasDisponibles,
                    d.nombre AS Departamento
                FROM TiposPermisos tp
                CROSS JOIN Empleados e
                LEFT JOIN SaldoPermisos sp 
                    ON e.id_empleado = sp.id_empleado 
                    AND sp.id_tipo_permiso = tp.id_tipo_permiso
                LEFT JOIN Departamentos d ON e.id_departamento = d.id_departamento
                WHERE e.id_empleado = @idEmpleado";
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@idEmpleado", idEmpleado);
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        da.Fill(dt);
                    }
                }
            }
            //Si hay datos, se extrae el departamento de la primera fila.
            if (dt.Rows.Count > 0)
            {
                lblDepartamento.InnerText = dt.Rows[0]["Departamento"].ToString();
            }
            gvPermisos.DataSource = dt;
            gvPermisos.DataBind();
        }
    }
}
