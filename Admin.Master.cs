using Sistema_RRHH.Clases;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Sistema_RRHH
{
    public partial class SiteMaster : MasterPage
    {
        string connectionString = System.Configuration.ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;
        protected void Page_Load(object sender, EventArgs e)
        {

            if (!IsPostBack)
            {
                if (Session["username"] != null)
                {
                    litUsuario.Text = "<b><i>" + Session["username"].ToString() + "</i></b>";
                }
                else
                {
                    Response.Redirect("Login.aspx"); // Redirigir
                }

                if (Session["rol"] != null)
                {
                    litRol.Text = "<b><i>" + Session["rol"].ToString() + "</i></b>"; //esto se mostrará en el sidebar

                    //Verificar el rol del usuario y ocultar el menú Administración si no es Admin o RH
                    string rolUsuario = Session["rol"].ToString();
                    if (rolUsuario == "admin")
                    {
                        //Admin ve todas las opciones
                        collapseAdmin.Visible = true;
                        headingRRHH.Visible = true;
                        collapsePermisos.Visible = true;
                        collapseEvaluaciones.Visible = true;
                        collapseAdminRh.Visible = true;
                        collapseAdmin.Visible = true;
                        collapseDashboard.Visible = true;
                        collapseReportes.Visible = true;
                        panelEmpleado.Visible = true;
                        collapseAnuncios.Visible = true;
                    }

                    else if (rolUsuario == "rh")
                    {
                        //RH ve opciones restringidas:
                        collapseAdmin.Visible = true;
                        headingRRHH.Visible = true;
                        collapsePermisos.Visible = true;
                        collapseEvaluaciones.Visible = true;
                        collapseAdminRh.Visible = true;
                        collapseAdmin.Visible = false;
                        panelEmpleado.Visible = false;   
                        collapseDashboard.Visible = true;
                        collapseReportes.Visible = true;
                        collapseAnuncios.Visible = true;
                    }

                    //Para empleados
                    else if (rolUsuario == "empleado")
                    {
                        collapseAdmin.Visible = false;       
                        headingRRHH.Visible = false;         
                        collapsePermisos.Visible = false;      
                        collapseEvaluaciones.Visible = false;
                        collapseAdmin.Visible = false;
                        collapseDashboard.Visible = false;
                        collapseReportes.Visible = false;
                        panelEmpleado.Visible = true;
                        collapseAdminRh.Visible = false;
                        collapseAnuncios.Visible = false;

                    }
                    //Para supervisores
                    else if (rolUsuario == "supervisor")
                    {
                        collapseAdmin.Visible = false;       
                        headingRRHH.Visible = false;         
                        collapsePermisos.Visible = true;      
                        collapseEvaluaciones.Visible = true;
                        collapseAdmin.Visible = false;
                        panelEmpleado.Visible = false;
                        collapseDashboard.Visible = false;
                        collapseReportes.Visible = false;
                        collapseAdminRh.Visible = false;
                        collapseAnuncios.Visible = false;
                    }
                    else
                    {
                        //para otros roles, se ocultan las opciones
                        collapseAdmin.Visible = false;
                        headingRRHH.Visible = false;
                        collapsePermisos.Visible = false;
                        collapseEvaluaciones.Visible = false;
                        collapseAdmin.Visible = false;
                        panelEmpleado.Visible = false;
                        collapseDashboard.Visible = false;
                        collapseReportes.Visible = false;
                        collapseAdminRh.Visible = false;
                        collapseAnuncios.Visible = false;
                    }
                }

                CargarNotificaciones();
            }
        }
        private void CargarNotificaciones()
        {
            if (Session["id_empleado"] != null)
            {
                int idEmpleado = Convert.ToInt32(Session["id_empleado"]);
                List<Notificacion> notificaciones = ObtenerNotificacionesNoLeidas(idEmpleado);
                rptNotificaciones.DataSource = notificaciones;
                rptNotificaciones.DataBind();
                //Actualizar la visibilidad del punto:
                notifCountNotificaciones.Visible = (notificaciones.Count > 0);
            }
        }

        //metodo auxiliar para obtener la lista de notificaciones no leídas desde la base de datos
        private List<Notificacion> ObtenerNotificacionesNoLeidas(int idEmpleado)
        {
            List<Notificacion> lista = new List<Notificacion>();
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "SELECT id_notificacion, mensaje, fecha_creacion, leido, tipo FROM Notificaciones WHERE id_empleado = @id_empleado AND leido = 0";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id_empleado", idEmpleado);
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            lista.Add(new Notificacion
                            {
                                Id = Convert.ToInt32(reader["id_notificacion"]),
                                Mensaje = reader["mensaje"].ToString(),
                                FechaCreacion = Convert.ToDateTime(reader["fecha_creacion"]),
                                Leido = Convert.ToBoolean(reader["leido"]),
                                Tipo = reader["tipo"].ToString()
                            });
                        }
                    }
                }
            }
            return lista;
        }

        //evento disparado al hacer click en el botón oculto, para marcar todas las notificaciones como leídas
        protected void btnMarcarNotificaciones_Click(object sender, EventArgs e)
        {
            if (Session["id_empleado"] != null)
            {
                int idEmpleado = Convert.ToInt32(Session["id_empleado"]);
                MarcarTodasNotificacionesLeidas(idEmpleado);
                CargarNotificaciones();
            }
        }

        //metodo que marca todas las notificaciones no leídas como leídas
        private void MarcarTodasNotificacionesLeidas(int idEmpleado)
        {
            
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "UPDATE Notificaciones SET leido = 1 WHERE id_empleado = @id_empleado AND leido = 0";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id_empleado", idEmpleado);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        public string GetNotificationRedirectUrl(string tipo)
        {
            string rol = Session["rol"] != null ? Session["rol"].ToString().ToLower() : "";
            switch (tipo.ToLower())
            {
                case "autoevaluacioncompleta":
                    //Notificación que recibe el supervisor cuando un empleado completa su autoevaluación.
                    //Redirige al supervisor a EvaluarEmpleados.aspx.
                    return "EvaluarEmpleados.aspx";
                case "evaluacioncompleta":
                    //Notificación que recibe el empleado cuando su supervisor completa su evaluación.
                    //Redirige al empleado a AutoEvaluacion.aspx.
                    return "AutoEvaluacion.aspx";
                case "permisosolicitado":
                    //Si el receptor es supervisor o RH, redirige a AprobarPermiso.aspx; de lo contrario, a HistorialPermisos.aspx.
                    if (rol == "supervisor" || rol == "rh")
                        return "AprobarPermiso.aspx";
                    else
                        return "HistorialPermisos.aspx";
                case "permisoaprobado":
                case "permisorechazado":
                    return "HistorialPermisos.aspx";
                default:
                    return "#";
            }
        }


    }

}

