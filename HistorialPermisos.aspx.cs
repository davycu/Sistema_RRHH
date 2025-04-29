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
    public partial class HistorialPermisos : System.Web.UI.Page
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
                CargarResumenPermisos();
                CargarHistorialPermisos();
            }
        }

        //carga el resumen de permisos (agrupado por tipo) para el empleado.
        //muestra el nombre del permiso, saldo (en días) (calculado desde la columna SaldoDiasReal),
        //horas disponibles y el total de horas solicitadas, y los días solicitados (horas/8).

        private void CargarResumenPermisos()
        {
            int idEmpleado = Session["id_empleado"] != null ? Convert.ToInt32(Session["id_empleado"]) : 0;
            if (idEmpleado == 0) return;

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = @"
                    SELECT 
                        tp.nombre_permiso,
                        sp.horas_disponibles,
                        sp.SaldoDiasReal,
                        ISNULL(SUM(p.horas_solicitadas), 0) AS total_horas_solicitadas
                    FROM TiposPermisos tp
                    LEFT JOIN SaldoPermisos sp 
                        ON tp.id_tipo_permiso = sp.id_tipo_permiso AND sp.id_empleado = @id_empleado
                    LEFT JOIN Permisos p 
                        ON tp.id_tipo_permiso = p.id_tipo_permiso AND p.id_empleado = @id_empleado
                    GROUP BY tp.nombre_permiso, sp.horas_disponibles, sp.SaldoDiasReal
                    ORDER BY tp.nombre_permiso";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id_empleado", idEmpleado);
                    SqlDataReader reader = cmd.ExecuteReader();
                    repeaterResumenPermisos.DataSource = reader;
                    repeaterResumenPermisos.DataBind();
                }
            }
        }

        //carga el historial detallado de permisos del empleado.
        private void CargarHistorialPermisos()
        {
            int idEmpleado = Session["id_empleado"] != null ? Convert.ToInt32(Session["id_empleado"]) : 0;
            if (idEmpleado == 0) return;

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = @"
                    SELECT 
                        p.id_permiso,
                        tp.codigo_permiso,
                        tp.nombre_permiso,
                        p.fecha_inicio,
                        p.fecha_fin,
                        p.horas_solicitadas,
                        p.fecha_solicitud,
                        p.estado,
                        p.documento,
                        p.comentarios_empleado,
                        p.comentarios_supervisor,
                        p.fecha_revisado,
                        p.revisado_por
                    FROM Permisos p
                    INNER JOIN TiposPermisos tp ON p.id_tipo_permiso = tp.id_tipo_permiso
                    WHERE p.id_empleado = @id_empleado
                    ORDER BY p.fecha_solicitud DESC";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id_empleado", idEmpleado);
                    SqlDataReader reader = cmd.ExecuteReader();
                    repeaterHistorialPermisos.DataSource = reader;
                    repeaterHistorialPermisos.DataBind();
                }
            }
        }

        public string GetStatusColor(string estado)
        {
            switch (estado.ToLower())
            {
                case "pendiente":
                    return "background-color:#fff3cd;";  // amarillo claro
                case "aprobado":
                    return "background-color:#d4edda;";  // verde claro
                case "rechazado":
                    return "background-color:#f8d7da;";  // rojo claro
                default:
                    return "";
            }
        }


    }
}