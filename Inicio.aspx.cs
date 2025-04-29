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
    public partial class InicioSupv : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

            if (Session["username"] == null) //Si la sesión de usuario no existe
            {
                Response.Redirect("Login.aspx"); //Redirigir al login
            }

            if (!IsPostBack)
            {

                CargarAnuncio();

                //Mostrar el nombre completo del usuario si existe en sesión
                if (Session["nombreCompleto"] != null)
                {
                    litNombreUsuario.Text = "¡Bienvenido, " + Session["nombreCompleto"].ToString() + "!";
                }
                else
                {
                    litNombreUsuario.Text = "¡Bienvenido!";
                }

                //no visible para rol empleado
                if (Session["rol"] != null && Session["rol"].ToString().ToLower() == "empleado")
                {
                    panelAccesosRapidos.Visible = false;
                }
            }

        }

        private void CargarAnuncio()
        {
            //Conexión a la base de datos
            using (SqlConnection conn = new SqlConnection(ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString))
            {
                conn.Open();
                //Consulta para obtener el anuncio activo más reciente
                string query = "SELECT TOP 1 mensaje FROM Anuncios WHERE activo = 1 ORDER BY fecha_publicacion DESC";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    object result = cmd.ExecuteScalar();
                    if (result != null)
                    {
                        litAnuncio.Text = result.ToString();
                        panelAnuncio.Visible = true;
                    }
                    else
                    {
                        panelAnuncio.Visible = false;
                    }
                }
            }
        }

    }
}