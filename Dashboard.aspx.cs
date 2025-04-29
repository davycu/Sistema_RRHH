using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Configuration;
using Sistema_RRHH.Clases;
using Newtonsoft.Json;

namespace Sistema_RRHH
{

	public partial class Dashboard : System.Web.UI.Page
	{
        string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;
        protected void Page_Load(object sender, EventArgs e)
		{

            Seguridad.VerificarAdminRh(this);

            if (!IsPostBack)
            {
                
                //cargar el grafico de barras a través de GetEmpleadosPorDepartamentoJSON()
                //cargar supervisores:
                DataTable dtSupervisores = GetSupervisoresPorDepartamento();
                gvSupervisores.DataSource = dtSupervisores;
                gvSupervisores.DataBind();

                CargarAniosDash();
                RenderPieChart();

                CargarAniosPermisos();
                CargarTiposPermiso();
                ddlAnioPermisos_SelectedIndexChanged(null, null);

                litTotalEmpleados.Text = GetTotalEmpleados().ToString();

                string json = GetEmpleadosPorGeneroJSON();
                ScriptManager.RegisterStartupScript(this, this.GetType(), "renderGeneroPie", $"renderGeneroPie({json});", true);

            }

        }

        public string GetEmpleadosPorDepartamentoJSON()
        {
            DataTable dt = new DataTable();
            string query = @"
                    SELECT 
                      d.nombre AS Departamento, 
                      COUNT(e.id_empleado) AS Cantidad
                    FROM Departamentos d
                    LEFT JOIN Empleados e ON d.id_departamento = e.id_departamento
                    GROUP BY d.nombre";

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
            //Newtonsoft para convertir el DataTable
            return Newtonsoft.Json.JsonConvert.SerializeObject(dt);
        }

        public int GetTotalEmpleados()
        {
            int count = 0;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                string sql = @"
                    SELECT COUNT(*) 
                    FROM Empleados e
                    INNER JOIN Usuarios u ON e.id_usuario = u.id_usuario
                    WHERE u.Estado = 'Activo'";
                using (SqlCommand cmd = new SqlCommand(sql, conn))
                {
                    conn.Open();
                    count = Convert.ToInt32(cmd.ExecuteScalar());
                }
            }
            return count;
        }


        private DataTable GetSupervisoresPorDepartamento()
        {
            DataTable dt = new DataTable();
            //un supervisor se identifica por tener un valor en id_supervisor_departamento
            // y que pertenece al mismo departamento; se filtra solo empleados activos (por Usuarios)
            string query = @"
                  SELECT 
                     d.nombre AS Departamento,
                     (s.nombre + ' ' + s.apellido) AS Supervisor,
                     s.fecha_ingreso AS FechaInicio,
                     s.salario AS Salario
                  FROM Empleados s
                  INNER JOIN Departamentos d ON s.id_departamento = d.id_departamento
                  INNER JOIN Usuarios u ON s.id_usuario = u.id_usuario
                  WHERE u.Estado = 'Activo'
                    AND s.id_supervisor_departamento IS NOT NULL";

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    conn.Open();
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        da.Fill(dt);
                    }
                }
            }
            return dt;
        }

        public string GetEvaluacionesCompletadasJSON()
        {
            int anio = int.Parse(ddlAnioDash.SelectedValue);
            DataTable dt = new DataTable();
            string sql = @"
      SELECT 
         SUM(CASE WHEN finalizada=0 THEN 1 ELSE 0 END) AS PendientesAuto,
         SUM(CASE WHEN finalizada=1 AND EvaluadaSupervisor=0 THEN 1 ELSE 0 END) AS PendientesSup,
         SUM(CASE WHEN EvaluadaSupervisor=1 THEN 1 ELSE 0 END) AS Completadas
      FROM Evaluaciones e
      INNER JOIN PeriodosEvaluacion pe ON e.id_periodo = pe.id_periodo
      WHERE pe.anio = @anio";

            using (var cmd = new SqlCommand(sql, new SqlConnection(connectionString)))
            {
                cmd.Parameters.AddWithValue("@anio", anio);
                var da = new SqlDataAdapter(cmd);
                da.Fill(dt);
            }

            var rows = new[]
            {
        new { label="Pendientes Autoevaluar", value=Convert.ToInt32(dt.Rows[0]["PendientesAuto"]) },
        new { label="Pendientes Supervisor", value=Convert.ToInt32(dt.Rows[0]["PendientesSup"]) },
        new { label="Completadas", value=Convert.ToInt32(dt.Rows[0]["Completadas"]) }
    };
            return JsonConvert.SerializeObject(rows);
        }

        protected void ddlAnioDash_SelectedIndexChanged(object sender, EventArgs e)
        {
            RenderPieChart();
        }

        private void RenderPieChart()
        {
            //el pie lee el JSON directamente del método GetEvaluacionesCompletadasJSON()
            //y se usara SelectedValue de ddlAnioDash para filtrar el año
        }

        private void CargarAniosDash()
        {
            DataTable dt = new DataTable();
            dt.Columns.Add("anio", typeof(int));
            using (var conn = new SqlConnection(connectionString))
            using (var cmd = new SqlCommand("SELECT DISTINCT anio FROM PeriodosEvaluacion ORDER BY anio ASC", conn))
            {
                conn.Open();
                var rdr = cmd.ExecuteReader();
                while (rdr.Read()) dt.Rows.Add(rdr.GetInt32(0));
            }
            ddlAnioDash.DataSource = dt;
            ddlAnioDash.DataTextField = ddlAnioDash.DataValueField = "anio";
            ddlAnioDash.DataBind();
        }

        private void CargarAniosPermisos()
        {
            DataTable dt = new DataTable();
            string sql = @"
                SELECT DISTINCT YEAR(fecha_inicio) AS anio
                FROM Permisos
                ORDER BY anio ASC";

            using (var conn = new SqlConnection(connectionString))
            using (var cmd = new SqlCommand(sql, conn))
            {
                conn.Open();
                new SqlDataAdapter(cmd).Fill(dt);
            }

            ddlAnioPermisos.DataSource = dt;
            ddlAnioPermisos.DataTextField = ddlAnioPermisos.DataValueField = "anio";
            ddlAnioPermisos.DataBind();

            //Selecciona automáticamente el primer año en la lista
            if (ddlAnioPermisos.Items.Count > 0)
                ddlAnioPermisos.SelectedIndex = 0;
        }

        protected void ddlAnioPermisos_SelectedIndexChanged(object sender, EventArgs e)
        {
            int anio = int.Parse(ddlAnioPermisos.SelectedValue);
            string json = GetPermisosPorMesJSON(anio);
            // Llama al JS para renderizar el gráfico SIN recargar la página completa
            ScriptManager.RegisterStartupScript(this, GetType(), "renderChart",
                $"loadPermisosChart('{HttpUtility.JavaScriptStringEncode(json)}');", true);
        }

        private string GetPermisosPorMesJSON(int anio)
        {
            DataTable dt = new DataTable();
            //Empezamos la consulta
            string sql = @"
                SELECT MONTH(fecha_inicio) AS Mes, COUNT(*) AS Cantidad
                FROM Permisos
                WHERE YEAR(fecha_inicio) = @anio";

            // Si se ha seleccionado un tipo de permiso distinto de "Todos"
            if (ddlTipoPermiso.SelectedValue != "0")
            {
                sql += " AND id_tipo_permiso = @idTipoPermiso";
            }

            sql += " GROUP BY MONTH(fecha_inicio) ORDER BY Mes";

            using (var conn = new SqlConnection(connectionString))
            using (var cmd = new SqlCommand(sql, conn))
            {
                cmd.Parameters.AddWithValue("@anio", anio);
                if (ddlTipoPermiso.SelectedValue != "0")
                {
                    int idTipo = int.Parse(ddlTipoPermiso.SelectedValue);
                    cmd.Parameters.AddWithValue("@idTipoPermiso", idTipo);
                }
                new SqlDataAdapter(cmd).Fill(dt);
            }

            var list = Enumerable.Range(1, 12)
                .Select(m => new {
                    Mes = m,
                    Cantidad = dt.AsEnumerable()
                    .FirstOrDefault(r => r.Field<int>("Mes") == m)?.Field<int>("Cantidad") ?? 0
                })
                .ToList();

            return Newtonsoft.Json.JsonConvert.SerializeObject(list);
        }

        protected void ddlTipoPermiso_SelectedIndexChanged(object sender, EventArgs e)
        {
            int anio = int.Parse(ddlAnioPermisos.SelectedValue);
            string json = GetPermisosPorMesJSON(anio);
            ScriptManager.RegisterStartupScript(this, GetType(), "renderChart",
                $"loadPermisosChart('{HttpUtility.JavaScriptStringEncode(json)}');", true);
        }


        private void CargarTiposPermiso()
        {
            DataTable dt = new DataTable();
            string sql = "SELECT id_tipo_permiso, nombre_permiso FROM TiposPermisos ORDER BY nombre_permiso";
            using (var conn = new SqlConnection(connectionString))
            using (var cmd = new SqlCommand(sql, conn))
            {
                conn.Open();
                new SqlDataAdapter(cmd).Fill(dt);
            }
            ddlTipoPermiso.DataSource = dt;
            ddlTipoPermiso.DataTextField = "nombre_permiso";
            ddlTipoPermiso.DataValueField = "id_tipo_permiso";
            ddlTipoPermiso.DataBind();
            //Agregar opción "Todos"
            ddlTipoPermiso.Items.Insert(0, new System.Web.UI.WebControls.ListItem("Todos", "0"));
        }

        [System.Web.Services.WebMethod]
        public static string GetEmpleadosPorGeneroJSON()
        {
            DataTable dt = new DataTable();
            //Se filtran solo los empleados que tengan un género definido.
            string query = @"
                 SELECT LOWER(e.genero) AS genero, COUNT(*) AS cantidad
                    FROM Empleados e
                    INNER JOIN Usuarios u ON e.id_usuario = u.id_usuario
                    WHERE u.Estado = 'Activo'
                      AND e.genero IS NOT NULL 
                      AND LTRIM(RTRIM(e.genero)) <> ''
                    GROUP BY LOWER(e.genero)";

            using (SqlConnection conn = new SqlConnection(ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString))
            {
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        da.Fill(dt);
                    }
                }
            }
            return Newtonsoft.Json.JsonConvert.SerializeObject(dt);
        }

    }
}