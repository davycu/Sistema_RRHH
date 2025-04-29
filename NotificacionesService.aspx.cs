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
	public partial class NotificacionesService : System.Web.UI.Page
	{
        [WebMethod]
        public static void MarcarNotificacionLeida(int notificacionId)
        {
            string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "UPDATE Notificaciones SET leido = 1 WHERE id_notificacion = @id";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id", notificacionId);
                    cmd.ExecuteNonQuery();
                }
            }
        }
    }
}