using Sistema_RRHH.Clases;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Sistema_RRHH
{
    public partial class CrearEmpleado : System.Web.UI.Page
    {
        string connectionString = ConfigurationManager.ConnectionStrings["CnxBdRRHH"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            //verificar el rol (solo admin y RH tienen acceso)
            Seguridad.VerificarAdminRh(this);

            if (!IsPostBack)
            {
                CargarEmpleados();
                CargarDepartamentos();
            }

        }

        //cargar los departamentos en los dropdowns:
        private void CargarDepartamentos()
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                //consulta para obtener id, código y nombre de departamentos
                SqlCommand cmd = new SqlCommand("SELECT id_departamento, codigo_departamento, nombre FROM Departamentos", conn);
                SqlDataReader reader = cmd.ExecuteReader();

                ddlDepartamento.Items.Clear();
                ddlDepartamento.Items.Add(new ListItem("Seleccione un departamento", "0"));

                ddlSupervisorDepto.Items.Clear();
                ddlSupervisorDepto.Items.Add(new ListItem("Seleccione (si es supervisor)", "0"));

                while (reader.Read())
                {
                    string displayText = $"{reader["codigo_departamento"]} - {reader["nombre"]}";
                    string idDepto = reader["id_departamento"].ToString();
                    ddlDepartamento.Items.Add(new ListItem(displayText, idDepto));
                    ddlSupervisorDepto.Items.Add(new ListItem(displayText, idDepto));
                }
            }
        }

        //cargar la lista de empleados en el repeater, uniendo con Departamentos para mostrar nombres
        private void CargarEmpleados()
        {
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                string query = @"
                    SELECT 
                        e.id_empleado,
                        e.codigo_empleado,
                        e.nombre,
                        e.apellido,
                        e.correo,
                        e.telefono,
                        e.cargo,
                        e.salario,
                        CONVERT(varchar, e.fecha_ingreso, 103) as fecha_ingreso, 
                        CONVERT(varchar, e.fecha_finalizacion, 103) as fecha_finalizacion,
                        e.TipoEmpleado,
                        e.Comentario,
                        d.nombre as departamento,
                        sd.nombre as supervisorDepto,
                        sup.codigoSupervisor as codigoSupervisor
                    FROM Empleados e
                    LEFT JOIN Departamentos d ON e.id_departamento = d.id_departamento
                    LEFT JOIN Departamentos sd ON e.id_supervisor_departamento = sd.id_departamento
                    LEFT JOIN SupervisoresDepartamento sup ON e.id_empleado = sup.id_empleado
                    ORDER BY e.id_empleado ASC";
                SqlCommand cmd = new SqlCommand(query, conn);
                SqlDataReader reader = cmd.ExecuteReader();

                repeaterEmpleados.DataSource = reader;
                repeaterEmpleados.DataBind();
            }
        }

        //metodo para guardar (insertar o actualizar) un empleado
        protected void btnGuardar_Click(object sender, EventArgs e)
        {
            litAlert.Text = "";

            //validaciones (nombre, correo, cargo, salario, fechas, departamento, tipo, etc.)

            string correo = txtCorreo.Text.Trim().ToLower();
            //validar que el correo termine en "@email.com"
            if (!correo.EndsWith("@email.com"))
            {
                litAlert.Text = "<div class='alert alert-danger'>El correo debe estar en minúsculas y tener el dominio @email.com.</div>";
                return;
            }

            //teléfono: se muestra +504 de forma estatica en el input group,
            //pero el usuario ingresa solo los 8 dígitos (con o sin guion).
            string telefonoIngresado = txtTelefono.Text.Trim();
            //extraer solo dígitos del valor ingresado.
            string digits = Regex.Replace(telefonoIngresado, "[^0-9]", "");
            if (digits.Length != 8)
            {
                litAlert.Text = "<div class='alert alert-danger'>El teléfono debe contener 8 dígitos.</div>";
                return;
            }

            //formatear el número para que se guarde con guion: "1234-5678"
            string telefonoFormateado = digits.Substring(0, 4) + "-" + digits.Substring(4);

            //validar que se haya seleccionado un departamento para el empleado (asignación normal)
            int idDepartamento = ddlDepartamento.SelectedValue != "0" ? Convert.ToInt32(ddlDepartamento.SelectedValue) : 0;
            if (idDepartamento == 0)
            {
                litAlert.Text = "<div class='alert alert-danger'>Seleccione un departamento.</div>";
                return;
            }
            //para el supervisor de departamento (este dropdown es opcional)
            int idSupervisorDepto = ddlSupervisorDepto.SelectedValue != "0" ? Convert.ToInt32(ddlSupervisorDepto.SelectedValue) : 0;

            //resto de validaciones para tipo de empleado, etc.

            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();

                //validar correo unico
                if (string.IsNullOrEmpty(hiddenEmpleadoId.Value))
                {
                    using (var cmdCheckEmail = new SqlCommand(
                        "SELECT COUNT(*) FROM Empleados WHERE LOWER(correo) = @correo", conn))
                    {
                        cmdCheckEmail.Parameters.AddWithValue("@correo", txtCorreo.Text.Trim().ToLower());
                        int emailCount = Convert.ToInt32(cmdCheckEmail.ExecuteScalar());
                        if (emailCount > 0)
                        {
                            litAlert.Text = "<div class='alert alert-danger'>Ya existe un empleado con ese correo.</div>";
                            return;
                        }
                    }
                }
                else
                {
                    using (var cmdCheckEmail = new SqlCommand(
                        "SELECT COUNT(*) FROM Empleados WHERE LOWER(correo) = @correo AND id_empleado <> @idEmpleado", conn))
                    {
                        cmdCheckEmail.Parameters.AddWithValue("@correo", txtCorreo.Text.Trim().ToLower());
                        cmdCheckEmail.Parameters.AddWithValue("@idEmpleado", Convert.ToInt32(hiddenEmpleadoId.Value));
                        int emailCount = Convert.ToInt32(cmdCheckEmail.ExecuteScalar());
                        if (emailCount > 0)
                        {
                            litAlert.Text = "<div class='alert alert-danger'>Ese correo ya está asignado a otro empleado.</div>";
                            return;
                        }
                    }
                }

                //validar para nombre+apellido unico
                string sqlNameCheck = @"
            SELECT COUNT(*) 
              FROM Empleados 
             WHERE LOWER(nombre) = @nombre 
               AND LOWER(apellido) = @apellido" +
                     (string.IsNullOrEmpty(hiddenEmpleadoId.Value)
                        ? ""
                        : " AND id_empleado <> @idEmpleado");
                using (var cmdCheckName = new SqlCommand(sqlNameCheck, conn))
                {
                    cmdCheckName.Parameters.AddWithValue("@nombre", txtNombre.Text.Trim().ToLower());
                    cmdCheckName.Parameters.AddWithValue("@apellido", txtApellido.Text.Trim().ToLower());
                    if (!string.IsNullOrEmpty(hiddenEmpleadoId.Value))
                        cmdCheckName.Parameters.AddWithValue("@idEmpleado", Convert.ToInt32(hiddenEmpleadoId.Value));

                    int nameCount = Convert.ToInt32(cmdCheckName.ExecuteScalar());
                    if (nameCount > 0)
                    {
                        litAlert.Text = "<div class='alert alert-danger'>Ya existe un empleado con ese mismo nombre y apellido.</div>";
                        return;
                    }
                }

                SqlCommand cmd;
                if (string.IsNullOrEmpty(hiddenEmpleadoId.Value)) // Nuevo empleado
                {
                    string insertQuery = @"
                            INSERT INTO Empleados 
                            (nombre, apellido, correo, telefono, id_departamento, cargo, salario, fecha_ingreso, fecha_finalizacion, TipoEmpleado, Comentario)
                            VALUES 
                            (@nombre, @apellido, @correo, @telefono, @id_departamento, @cargo, @salario, @fecha_ingreso, @fecha_finalizacion, @TipoEmpleado, @Comentario);
                            SELECT SCOPE_IDENTITY();";
                    cmd = new SqlCommand(insertQuery, conn);
                    cmd.Parameters.AddWithValue("@nombre", txtNombre.Text.Trim());
                    cmd.Parameters.AddWithValue("@apellido", txtApellido.Text.Trim());
                    cmd.Parameters.AddWithValue("@correo", txtCorreo.Text.Trim());
                    cmd.Parameters.AddWithValue("@telefono", txtTelefono.Text.Trim());
                    cmd.Parameters.AddWithValue("@cargo", txtCargo.Text.Trim());

                    decimal salario;
                    if (!decimal.TryParse(txtSalario.Text.Trim(), out salario))
                    {
                        litAlert.Text = "<div class='alert alert-danger'>El salario debe ser un número decimal válido.</div>";
                        return;
                    }
                    cmd.Parameters.AddWithValue("@salario", salario);

                    DateTime fechaIngreso;
                    if (!DateTime.TryParse(txtFechaIngreso.Text.Trim(), out fechaIngreso))
                    {
                        litAlert.Text = "<div class='alert alert-danger'>La fecha de ingreso debe tener un formato válido.</div>";
                        return;
                    }
                    cmd.Parameters.AddWithValue("@fecha_ingreso", fechaIngreso);

                    //manejo de fecha_finalizacion:
                    DateTime fechaFinalizacion;
                    if (!string.IsNullOrWhiteSpace(txtFechaFinalizacion.Text) && DateTime.TryParse(txtFechaFinalizacion.Text.Trim(), out fechaFinalizacion))
                    {
                        cmd.Parameters.AddWithValue("@fecha_finalizacion", fechaFinalizacion);
                    }
                    else
                    {
                        cmd.Parameters.AddWithValue("@fecha_finalizacion", DBNull.Value);
                    }

                    cmd.Parameters.AddWithValue("@TipoEmpleado", ddlTipoEmpleado.SelectedValue);
                    cmd.Parameters.AddWithValue("@Comentario", txtComentario.Text.Trim());
                    cmd.Parameters.AddWithValue("@id_departamento", idDepartamento);

                    int newId = Convert.ToInt32(cmd.ExecuteScalar());
                    litAlert.Text = "<div class='alert alert-success'>Empleado guardado correctamente.</div>";

                    //si se seleccionó un departamento para supervisión (idSupervisorDepto > 0)
                    if (idSupervisorDepto > 0)
                    {
                        //insertar en SupervisoresDepartamento:
                        SqlCommand cmdSupervisor = new SqlCommand(
                            "INSERT INTO SupervisoresDepartamento (id_empleado, id_departamento) VALUES (@id_empleado, @id_departamento)",
                            conn);
                        cmdSupervisor.Parameters.AddWithValue("@id_empleado", newId);
                        cmdSupervisor.Parameters.AddWithValue("@id_departamento", idSupervisorDepto);
                        cmdSupervisor.ExecuteNonQuery();

                        //actualizar la tabla Empleados para asignar id_supervisor_departamento:
                        SqlCommand updateSupervisor = new SqlCommand(
                            "UPDATE Empleados SET id_supervisor_departamento = @id_supervisor_depto WHERE id_empleado = @id_empleado",
                            conn);
                        updateSupervisor.Parameters.AddWithValue("@id_supervisor_depto", idSupervisorDepto);
                        updateSupervisor.Parameters.AddWithValue("@id_empleado", newId);
                        updateSupervisor.ExecuteNonQuery();
                    }
                }
                else //actualizar
                {
                    string updateQuery = @"
                            UPDATE Empleados 
                            SET nombre = @nombre,
                                apellido = @apellido,
                                correo = @correo,
                                telefono = @telefono,
                                id_departamento = @id_departamento,
                                cargo = @cargo,
                                salario = @salario,
                                fecha_ingreso = @fecha_ingreso,
                                fecha_finalizacion = @fecha_finalizacion,
                                TipoEmpleado = @TipoEmpleado,
                                Comentario = @Comentario
                            WHERE id_empleado = @id_empleado";
                    cmd = new SqlCommand(updateQuery, conn);
                    cmd.Parameters.AddWithValue("@nombre", txtNombre.Text.Trim());
                    cmd.Parameters.AddWithValue("@apellido", txtApellido.Text.Trim());
                    cmd.Parameters.AddWithValue("@correo", txtCorreo.Text.Trim());
                    cmd.Parameters.AddWithValue("@telefono", txtTelefono.Text.Trim());
                    cmd.Parameters.AddWithValue("@cargo", txtCargo.Text.Trim());

                    decimal salario;
                    if (!decimal.TryParse(txtSalario.Text.Trim(), out salario))
                    {
                        litAlert.Text = "<div class='alert alert-danger'>El salario debe ser un número decimal válido.</div>";
                        return;
                    }
                    cmd.Parameters.AddWithValue("@salario", salario);

                    DateTime fechaIngreso;
                    if (!DateTime.TryParse(txtFechaIngreso.Text.Trim(), out fechaIngreso))
                    {
                        litAlert.Text = "<div class='alert alert-danger'>La fecha de ingreso debe tener un formato válido.</div>";
                        return;
                    }
                    cmd.Parameters.AddWithValue("@fecha_ingreso", fechaIngreso);

                    DateTime fechaFinalizacion;
                    if (!string.IsNullOrWhiteSpace(txtFechaFinalizacion.Text) && DateTime.TryParse(txtFechaFinalizacion.Text.Trim(), out fechaFinalizacion))
                    {
                        cmd.Parameters.AddWithValue("@fecha_finalizacion", fechaFinalizacion);
                    }
                    else
                    {
                        cmd.Parameters.AddWithValue("@fecha_finalizacion", DBNull.Value);
                    }

                    cmd.Parameters.AddWithValue("@TipoEmpleado", ddlTipoEmpleado.SelectedValue);
                    cmd.Parameters.AddWithValue("@Comentario", txtComentario.Text.Trim());
                    cmd.Parameters.AddWithValue("@id_empleado", hiddenEmpleadoId.Value);
                    cmd.Parameters.AddWithValue("@id_departamento", idDepartamento);

                    cmd.ExecuteNonQuery();
                    litAlert.Text = "<div class='alert alert-success'>Empleado actualizado correctamente.</div>";

                    //eliminar registro anterior en SupervisoresDepartamento para este empleado
                    SqlCommand deleteSupervisor = new SqlCommand("DELETE FROM SupervisoresDepartamento WHERE id_empleado = @id_empleado", conn);
                    deleteSupervisor.Parameters.AddWithValue("@id_empleado", hiddenEmpleadoId.Value);
                    deleteSupervisor.ExecuteNonQuery();

                    //si se seleccionó un departamento para supervisión, insertar y actualizar
                    if (idSupervisorDepto > 0)
                    {
                        SqlCommand cmdSupervisor = new SqlCommand(
                            "INSERT INTO SupervisoresDepartamento (id_empleado, id_departamento) VALUES (@id_empleado, @id_departamento)",
                            conn);
                        cmdSupervisor.Parameters.AddWithValue("@id_empleado", hiddenEmpleadoId.Value);
                        cmdSupervisor.Parameters.AddWithValue("@id_departamento", idSupervisorDepto);
                        cmdSupervisor.ExecuteNonQuery();

                        SqlCommand updateSupervisor = new SqlCommand(
                            "UPDATE Empleados SET id_supervisor_departamento = @id_supervisor_depto WHERE id_empleado = @id_empleado",
                            conn);
                        updateSupervisor.Parameters.AddWithValue("@id_supervisor_depto", idSupervisorDepto);
                        updateSupervisor.Parameters.AddWithValue("@id_empleado", hiddenEmpleadoId.Value);
                        updateSupervisor.ExecuteNonQuery();
                    }
                    else
                    {
                        //si no se seleccionó supervisor, asegurarse de poner en NULL el campo en Empleados
                        SqlCommand updateSupervisor = new SqlCommand(
                            "UPDATE Empleados SET id_supervisor_departamento = NULL WHERE id_empleado = @id_empleado",
                            conn);
                        updateSupervisor.Parameters.AddWithValue("@id_empleado", hiddenEmpleadoId.Value);
                        updateSupervisor.ExecuteNonQuery();
                    }
                }
                CargarEmpleados();
                LimpiarFormulario();
            }
        }

        //cargar los datos del empleado seleccionado para edición
        protected void btnEditar_Click(object sender, EventArgs e)
        {
            litAlert.Text = "";
            Button btn = (Button)sender;
            string empleadoId = btn.CommandArgument;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                SqlCommand cmd = new SqlCommand("SELECT * FROM Empleados WHERE id_empleado=@id_empleado", conn);
                cmd.Parameters.AddWithValue("@id_empleado", empleadoId);
                SqlDataReader reader = cmd.ExecuteReader();
                if (reader.Read())
                {
                    hiddenEmpleadoId.Value = reader["id_empleado"].ToString();
                    txtNombre.Text = reader["nombre"].ToString();
                    txtApellido.Text = reader["apellido"].ToString();
                    txtCorreo.Text = reader["correo"].ToString();
                    txtTelefono.Text = reader["telefono"].ToString();
                    txtCargo.Text = reader["cargo"].ToString();
                    txtSalario.Text = reader["salario"].ToString();
                    txtFechaIngreso.Text = Convert.ToDateTime(reader["fecha_ingreso"]).ToString("yyyy-MM-dd");
                    txtFechaFinalizacion.Text = reader["fecha_finalizacion"] == DBNull.Value ? "" : Convert.ToDateTime(reader["fecha_finalizacion"]).ToString("yyyy-MM-dd");
                    ddlTipoEmpleado.SelectedValue = reader["TipoEmpleado"].ToString();
                    txtComentario.Text = reader["Comentario"].ToString();

                    if (reader["id_departamento"] != DBNull.Value)
                        ddlDepartamento.SelectedValue = reader["id_departamento"].ToString();
                    else
                        ddlDepartamento.SelectedIndex = 0;
                }
                reader.Close();

                //consultar si el empleado es supervisor de algún departamento
                SqlCommand cmdSupervisor = new SqlCommand(
                    "SELECT id_departamento FROM SupervisoresDepartamento WHERE id_empleado=@id_empleado",
                    conn);
                cmdSupervisor.Parameters.AddWithValue("@id_empleado", empleadoId);
                object supervisorDepto = cmdSupervisor.ExecuteScalar();
                if (supervisorDepto != null)
                {
                    ddlSupervisorDepto.SelectedValue = supervisorDepto.ToString();
                }
                else
                {
                    ddlSupervisorDepto.SelectedValue = "0";
                }
            }
        }

        //eliminar el empleado seleccionado
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

            Button btnEliminar = (Button)sender;
            string empleadoId = btnEliminar.CommandArgument;
            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();
                SqlCommand deleteCmd = new SqlCommand("DELETE FROM Empleados WHERE id_empleado=@id_empleado", conn);
                deleteCmd.Parameters.AddWithValue("@id_empleado", empleadoId);
                deleteCmd.ExecuteNonQuery();
                litAlert.Text = "<div class='alert alert-success'>Empleado eliminado correctamente.</div>";
                CargarEmpleados();
                LimpiarFormulario();
            }
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


        //limpia los campos del formulario
        private void LimpiarFormulario()
        {
            hiddenEmpleadoId.Value = "";
            txtNombre.Text = "";
            txtApellido.Text = "";
            txtCorreo.Text = "";
            txtTelefono.Text = "";
            txtCargo.Text = "";
            txtSalario.Text = "";
            txtFechaIngreso.Text = "";
            txtFechaFinalizacion.Text = "";
            ddlTipoEmpleado.SelectedIndex = 0;
            txtComentario.Text = "";
            ddlDepartamento.SelectedIndex = 0;
            ddlSupervisorDepto.SelectedIndex = 0;
        }

        protected void btnCancelar_Click(object sender, EventArgs e)
        {
            litAlert.Text = "";
            LimpiarFormulario();
        }

    }

}
    
