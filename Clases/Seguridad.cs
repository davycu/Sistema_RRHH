using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;

namespace Sistema_RRHH.Clases
{
    public class Seguridad
    {
        //validacion para paginas que tienen acceso perfiles admin y rh
        public static void VerificarAdminRh(Page pagina)
        {
            if (pagina.Session["username"] == null ||
                (pagina.Session["id_empleado"] == null && pagina.Session["username"].ToString().ToLower() != "admin"))
            {
                pagina.Response.Redirect("Login.aspx");
            }
            if (pagina.Session["rol"] == null ||
                (pagina.Session["rol"].ToString().ToLower() != "admin" &&
                 pagina.Session["rol"].ToString().ToLower() != "rh"))
            {
                pagina.Response.Redirect("SinAcceso.aspx");
            }
        }

        //validacion de acceso para admin, rh y supervisor
        public static void VerificarSupervisor(Page pagina)
        {
            if (pagina.Session["username"] == null ||
                (pagina.Session["id_empleado"] == null && pagina.Session["username"].ToString().ToLower() != "admin"))
            {
                pagina.Response.Redirect("Login.aspx");
            }
            if (pagina.Session["rol"] == null ||
                (pagina.Session["rol"].ToString().ToLower() != "admin" &&
                 pagina.Session["rol"].ToString().ToLower() != "rh" &&
                 pagina.Session["rol"].ToString().ToLower() !="supervisor"))
            {
                pagina.Response.Redirect("SinAcceso.aspx");
            }
        }

        //validacion para acceso perfil admin
        public static void VerificarAdmin(Page pagina)
        {
            if (pagina.Session["username"] == null ||
                (pagina.Session["id_empleado"] == null && pagina.Session["username"].ToString().ToLower() != "admin"))
            {
                pagina.Response.Redirect("Login.aspx");
            }
            if (pagina.Session["rol"] == null ||
                (pagina.Session["rol"].ToString().ToLower() != "admin"))
            {
                pagina.Response.Redirect("SinAcceso.aspx");
            }
        }

    }
}