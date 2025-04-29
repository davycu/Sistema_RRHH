using Sistema_RRHH.Clases;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Data;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Sistema_RRHH
{
    public partial class Anuncios : System.Web.UI.Page
    {
        string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;
        protected void Page_Load(object sender, EventArgs e)
        {

            //Validar sesión
            Seguridad.VerificarAdminRh(this);

            if (!IsPostBack)
            {

                CargarAnuncios();

            }
        }

        private void CargarAnuncios()
        {

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                //consulta que une la tabla de Anuncios con Usuarios para obtener los nombres de creación y modificación
                string query = @"
                    SELECT a.id_anuncio, a.titulo, a.mensaje, a.fecha_publicacion, a.activo, 
                           uc.username AS usuario_creacion, 
                           a.fecha_modificacion, 
                           um.username AS usuario_modificacion
                    FROM Anuncios a
                    INNER JOIN Usuarios uc ON a.id_usuario_creacion = uc.id_usuario
                    LEFT JOIN Usuarios um ON a.id_usuario_modificacion = um.id_usuario
                    ORDER BY a.fecha_publicacion DESC";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    DataTable dt = new DataTable();
                    SqlDataAdapter da = new SqlDataAdapter(cmd);
                    da.Fill(dt);
                    repeaterAnuncios.DataSource = dt;
                    repeaterAnuncios.DataBind();
                }
            }
        }

        protected void btnGuardar_Click(object sender, EventArgs e)
        {
            litAlert.Text = "";

            if (string.IsNullOrWhiteSpace(txtTitulo.Text))
            {
                litAlert.Text = "<div class='alert alert-danger'>Debe agregar un título para el anuncio.</div>";
                return;
            }
            if (string.IsNullOrWhiteSpace(txtMensaje.Text))
            {
                litAlert.Text = "<div class='alert alert-danger'>Debe ingresar el mensaje del anuncio.</div>";
                return;
            }

            string titulo = txtTitulo.Text.Trim();
            string mensaje = txtMensaje.Text.Trim();
            bool activo = chkActivo.Checked;
            int idUsuario = Convert.ToInt32(Session["id_usuario"]);
            DateTime now = DateTime.Now;

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                if (string.IsNullOrEmpty(hiddenAnuncioId.Value))
                {
                    //Insertar nuevo anuncio
                    string query = @"
                        INSERT INTO Anuncios (titulo, mensaje, activo, id_usuario_creacion)
                        VALUES (@titulo, @mensaje, @activo, @id_usuario_creacion)";
                    using (SqlCommand cmd = new SqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("@titulo", titulo);
                        cmd.Parameters.AddWithValue("@mensaje", mensaje);
                        cmd.Parameters.AddWithValue("@activo", activo);
                        cmd.Parameters.AddWithValue("@id_usuario_creacion", idUsuario);
                        cmd.ExecuteNonQuery();
                    }
                    litAlert.Text = "<div class='alert alert-success'>Anuncio guardado exitosamente.</div>";

                }
                else
                {
                    // Actualizar anuncio existente
                    int idAnuncio = Convert.ToInt32(hiddenAnuncioId.Value);
                    string query = @"
                        UPDATE Anuncios
                        SET titulo = @titulo, 
                            mensaje = @mensaje,
                            activo = @activo,
                            id_usuario_modificacion = @id_usuario_modificacion,
                            fecha_modificacion = @fecha_modificacion
                        WHERE id_anuncio = @id_anuncio";
                    using (SqlCommand cmd = new SqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("@titulo", titulo);
                        cmd.Parameters.AddWithValue("@mensaje", mensaje);
                        cmd.Parameters.AddWithValue("@activo", activo);
                        cmd.Parameters.AddWithValue("@id_usuario_modificacion", idUsuario);
                        cmd.Parameters.AddWithValue("@fecha_modificacion", now);
                        cmd.Parameters.AddWithValue("@id_anuncio", idAnuncio);
                        cmd.ExecuteNonQuery();
                    }
                    litAlert.Text = "<div class='alert alert-success'>Anuncio actualizado exitosamente.</div>";

                }
            }
            LimpiarFormulario();
            CargarAnuncios();
        }

        protected void btnCancelar_Click(object sender, EventArgs e)
        {
            litAlert.Text = "";
            LimpiarFormulario();
        }

        private void LimpiarFormulario()
        {
            
            txtTitulo.Text = "";
            txtMensaje.Text = "";
            chkActivo.Checked = false;
            hiddenAnuncioId.Value = "";
        }

        protected void btnEditar_Click(object sender, EventArgs e)
        {
            litAlert.Text = "";
            Button btn = (Button)sender;
            int idAnuncio = Convert.ToInt32(btn.CommandArgument);
            CargarAnuncioParaEdicion(idAnuncio);
        }

        private void CargarAnuncioParaEdicion(int idAnuncio)
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "SELECT id_anuncio, titulo, mensaje, activo FROM Anuncios WHERE id_anuncio = @id_anuncio";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id_anuncio", idAnuncio);
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            hiddenAnuncioId.Value = reader["id_anuncio"].ToString();
                            txtTitulo.Text = reader["titulo"].ToString();
                            txtMensaje.Text = reader["mensaje"].ToString();
                            chkActivo.Checked = Convert.ToBoolean(reader["activo"]);
                        }
                    }
                }
            }
        }

        protected void btnEliminar_Click(object sender, EventArgs e)
        {
            litAlert.Text = "";

            Button btn = (Button)sender;
            int idAnuncio = Convert.ToInt32(btn.CommandArgument);
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = "DELETE FROM Anuncios WHERE id_anuncio = @id_anuncio";
                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    cmd.Parameters.AddWithValue("@id_anuncio", idAnuncio);
                    cmd.ExecuteNonQuery();
                }
            }
            litAlert.Text = "<div class='alert alert-success'>Anuncio eliminado exitosamente.</div>";
            CargarAnuncios();
        }
    }
}
