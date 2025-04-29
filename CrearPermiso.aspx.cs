using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using Sistema_RRHH.Clases;

namespace Sistema_RRHH
{
    public partial class CrearPermiso : System.Web.UI.Page
    {
        string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {

            Seguridad.VerificarAdminRh(this);

            if (!IsPostBack)
            {
                CargarTiposPermisos();
            }
        }

        //Cargar los tipos de permisos en el repeater
        private void CargarTiposPermisos()
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = @"
                    SELECT id_tipo_permiso, nombre_permiso, justificacion, dias_maximos_anuales, dias_maximos_mensuales, requiere_documento, codigo_permiso
                    FROM dbo.TiposPermisos
                    ORDER BY id_tipo_permiso ASC";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    SqlDataReader reader = cmd.ExecuteReader();
                    repeaterTiposPermisos.DataSource = reader;
                    repeaterTiposPermisos.DataBind();
                }
            }
        }

        //Guarda un tipo de permiso
        protected void btnGuardar_Click(object sender, EventArgs e)
        {
            litAlert.Text = "";

            //Validar campos obligatorios
            if (string.IsNullOrWhiteSpace(txtNombrePermiso.Text))
            {
                litAlert.Text = "<div class='alert alert-danger'>El nombre del permiso es obligatorio.</div>";
                return;
            }
            if (string.IsNullOrWhiteSpace(txtJustificacion.Text))
            {
                litAlert.Text = "<div class='alert alert-danger'>La justificación es obligatoria.</div>";
                return;
            }

            //Validar longitud máxima de campos
            string nombre = txtNombrePermiso.Text.Trim();
            string justificacion = txtJustificacion.Text.Trim();
            if (nombre.Length > 50)
            {
                litAlert.Text = "<div class='alert alert-danger'>El nombre del permiso no debe exceder 50 caracteres.</div>";
                return;
            }
            if (justificacion.Length > 255)
            {
                litAlert.Text = "<div class='alert alert-danger'>La justificación no debe exceder 255 caracteres.</div>";
                return;
            }

            int diasAnuales;
            if (!int.TryParse(txtDiasMaxAnuales.Text.Trim(), out diasAnuales))
            {
                litAlert.Text = "<div class='alert alert-danger'>El campo Días Máx Anuales debe ser numérico.</div>";
                return;
            }

            int diasMensuales = 0;
            if (!string.IsNullOrWhiteSpace(txtDiasMaxMensuales.Text))
            {
                if (!int.TryParse(txtDiasMaxMensuales.Text.Trim(), out diasMensuales))
                {
                    litAlert.Text = "<div class='alert alert-danger'>El campo Días Máx Mensuales debe ser numérico.</div>";
                    return;
                }
            }

            bool requiereDocumento = chkRequiereDocumento.Checked;

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                //Si hiddenTipoPermiso está vacío, es inserción; de lo contrario, actualización.
                if (string.IsNullOrEmpty(hiddenTipoPermiso.Value))
                {
                    string insertQuery = @"
                        INSERT INTO TiposPermisos (nombre_permiso, justificacion, dias_maximos_anuales, dias_maximos_mensuales, requiere_documento)
                        VALUES (@nombre_permiso, @justificacion, @dias_maximos_anuales, @dias_maximos_mensuales, @requiere_documento);
                        SELECT SCOPE_IDENTITY();";
                    using (SqlCommand cmd = new SqlCommand(insertQuery, conn))
                    {
                        cmd.Parameters.AddWithValue("@nombre_permiso", txtNombrePermiso.Text.Trim());
                        cmd.Parameters.AddWithValue("@justificacion", txtJustificacion.Text.Trim());
                        cmd.Parameters.AddWithValue("@dias_maximos_anuales", diasAnuales);
                        if (string.IsNullOrWhiteSpace(txtDiasMaxMensuales.Text))
                            cmd.Parameters.AddWithValue("@dias_maximos_mensuales", DBNull.Value);
                        else
                            cmd.Parameters.AddWithValue("@dias_maximos_mensuales", diasMensuales);
                        cmd.Parameters.AddWithValue("@requiere_documento", requiereDocumento);

                        int newId = Convert.ToInt32(cmd.ExecuteScalar());
                        litAlert.Text = "<div class='alert alert-success'>Tipo de Permiso creado correctamente.</div>";
                    }
                }
                else
                {
                    //Actualización
                    string updateQuery = @"
                        UPDATE TiposPermisos 
                        SET nombre_permiso = @nombre_permiso,
                            justificacion = @justificacion,
                            dias_maximos_anuales = @dias_maximos_anuales,
                            dias_maximos_mensuales = @dias_maximos_mensuales,
                            requiere_documento = @requiere_documento
                        WHERE id_tipo_permiso = @id_tipo_permiso";
                    using (SqlCommand cmd = new SqlCommand(updateQuery, conn))
                    {
                        cmd.Parameters.AddWithValue("@nombre_permiso", txtNombrePermiso.Text.Trim());
                        cmd.Parameters.AddWithValue("@justificacion", txtJustificacion.Text.Trim());
                        cmd.Parameters.AddWithValue("@dias_maximos_anuales", diasAnuales);
                        if (string.IsNullOrWhiteSpace(txtDiasMaxMensuales.Text))
                            cmd.Parameters.AddWithValue("@dias_maximos_mensuales", DBNull.Value);
                        else
                            cmd.Parameters.AddWithValue("@dias_maximos_mensuales", diasMensuales);
                        cmd.Parameters.AddWithValue("@requiere_documento", requiereDocumento);
                        cmd.Parameters.AddWithValue("@id_tipo_permiso", hiddenTipoPermiso.Value);
                        cmd.ExecuteNonQuery();
                        litAlert.Text = "<div class='alert alert-success'>Tipo de Permiso actualizado correctamente.</div>";
                    }
                }
                LimpiarFormulario();
                CargarTiposPermisos();
            }
        }

        //metodo para editar un tipo de permiso
        protected void btnEditar_Click(object sender, EventArgs e)
        {
            litAlert.Text = "";
            System.Web.UI.WebControls.Button btn = (System.Web.UI.WebControls.Button)sender;
            string idTipo = btn.CommandArgument;
            hiddenTipoPermiso.Value = idTipo;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "SELECT * FROM dbo.TiposPermisos WHERE id_tipo_permiso = @id_tipo_permiso";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id_tipo_permiso", idTipo);
                    SqlDataReader reader = cmd.ExecuteReader();
                    if (reader.Read())
                    {
                        txtNombrePermiso.Text = reader["nombre_permiso"].ToString();
                        txtJustificacion.Text = reader["justificacion"].ToString();
                        txtDiasMaxAnuales.Text = reader["dias_maximos_anuales"].ToString();
                        txtDiasMaxMensuales.Text = reader["dias_maximos_mensuales"] == DBNull.Value ? "" : reader["dias_maximos_mensuales"].ToString();
                        chkRequiereDocumento.Checked = Convert.ToBoolean(reader["requiere_documento"]);
                    }
                }
            }
        }

        //metodo para eliminar un tipo de permiso
        protected void btnEliminar_Click(object sender, EventArgs e)
        {
            litAlert.Text = "";

            //verificar el rol del usuario desde la sesión.
            string rolUsuario = Session["rol"] != null ? Session["rol"].ToString().ToLower() : "";
            if (rolUsuario != "admin")
            {
                litAlert.Text = "<div class='alert alert-danger'>No tiene permisos para eliminar este registro.</div>";
                return;
            }

            System.Web.UI.WebControls.Button btnEliminar = (System.Web.UI.WebControls.Button)sender;
            string idTipo = btnEliminar.CommandArgument;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string deleteQuery = "DELETE FROM dbo.TiposPermisos WHERE id_tipo_permiso = @id_tipo_permiso";
                using (SqlCommand cmd = new SqlCommand(deleteQuery, conn))
                {
                    cmd.Parameters.AddWithValue("@id_tipo_permiso", idTipo);
                    cmd.ExecuteNonQuery();
                    litAlert.Text = "<div class='alert alert-success'>Tipo de Permiso eliminado correctamente.</div>";
                }
            }
            LimpiarFormulario();
            CargarTiposPermisos();
        }

        protected void ocultarBtnEliminar(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType == ListItemType.Item || e.Item.ItemType == ListItemType.AlternatingItem)
            {
                Button btnEliminar = (Button)e.Item.FindControl("btnEliminar");
                if (btnEliminar != null)
                {
                    string rolUsuario = Session["rol"] != null ? Session["rol"].ToString().ToLower() : "";
                    if (rolUsuario != "admin")
                    {
                        btnEliminar.Visible = false;
                    }
                }
            }
        }

        //limpiar los controles del formulario
        private void LimpiarFormulario()
        {
            hiddenTipoPermiso.Value = "";
            txtNombrePermiso.Text = "";
            txtJustificacion.Text = "";
            txtDiasMaxAnuales.Text = "";
            txtDiasMaxMensuales.Text = "";
            chkRequiereDocumento.Checked = false;
        }

        protected void btnCancelar_Click(object sender, EventArgs e)
        {
            LimpiarFormulario();
            litAlert.Text = "";
        }

    }
}


    
