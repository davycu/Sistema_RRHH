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
	public partial class Auditoria : System.Web.UI.Page
	{
        String connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {

            Seguridad.VerificarAdmin(this);

            if (!IsPostBack)
            {
                CargarAuditoria();
            }
        }

        private void CargarAuditoria()
        {
            DataTable dt = new DataTable();
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                //Seleccionamos las columnas más relevantes de la tabla Auditoria
                string query = @"
                    SELECT id_auditoria, tabla_afectada, id_registro, tipo_accion, fecha_cambio, usuario_modificador
                    FROM Auditoria
                    ORDER BY fecha_cambio DESC";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        da.Fill(dt);
                    }
                }
            }
            gvAuditoria.DataSource = dt;
            gvAuditoria.DataBind();
        }
    }
}
