using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Sistema_RRHH
{
	public partial class ManualUsuario : System.Web.UI.Page
	{
		protected void Page_Load(object sender, EventArgs e)
		{

            if (Session["username"] == null)
            {
                Response.Redirect("Login.aspx");
            }

            if (!IsPostBack)
            {
                //Determinar el rol del usuario para mostrar solo su sección
                string rol = Session["rol"] != null ? Session["rol"].ToString().ToLower() : "";

                switch (rol)
                {
                    case "empleado":
                        panelEmpleado.Visible = true;
                        break;
                    case "supervisor":
                        panelSupervisor.Visible = true;
                        break;
                    case "rh":
                        panelRH.Visible = true;
                        break;
                    case "admin":
                        panelAdmin.Visible = true;
                        break;
                    default:
                        Response.Redirect("Login.aspx");
                        break;
                }

                //Hacer visible el boton de descarga solo para admin, rh y supervisor
                if (rol == "admin" || rol == "rh" || rol == "supervisor")
                {
                    hlDescargarPDF.Visible = true;
                }
                else
                {
                    hlDescargarPDF.Visible = false;
                }

            }

        }
	}
}