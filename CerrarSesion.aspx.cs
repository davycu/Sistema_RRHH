using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Sistema_RRHH
{
    public partial class CerrarSesion : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

            //Cerrar sesión
            Session.Clear(); //Elimina todas las variables de sesión
            Session.Abandon(); //termina la sesión actual

            //Eliminar cookies de autenticación si las hay
            if (Request.Cookies["ASP.NET_SessionId"] != null)
            {
                Response.Cookies["ASP.NET_SessionId"].Expires = DateTime.Now.AddDays(-1);
            }

            //Redirigir al login
            Response.Redirect("Login.aspx");

        }
    }
}