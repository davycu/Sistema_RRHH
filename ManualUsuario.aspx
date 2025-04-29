<%@ Page Title="" Language="C#" MasterPageFile="~/Admin.Master" AutoEventWireup="true" CodeBehind="ManualUsuario.aspx.cs" Inherits="Sistema_RRHH.ManualUsuario" %>
<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Manual de Usuario por Rol
</asp:Content>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="server">

    <div class="container mt-4">
       
        <!-- Panel para Rol Empleado -->
        <asp:Panel ID="panelEmpleado" runat="server" Visible="false" CssClass="card mb-4">
            <div class="card-header">
                <h3 class="mb-0">Manual de Usuario - Rol Empleado</h3>
            </div>
            <div class="card-body">
                <p>El perfil <strong>Empleado</strong> está destinado a los colaboradores de la empresa. 
                Desde este rol podrás:</p>
                <ul>
                    <li>Solicitar permisos y visualizar su saldo disponible.</li>
                    <li>Revisar tu historial de permisos aprobados o rechazados.</li>
                    <li>Realizar autoevaluaciones periódicas.</li>
                    <li>Ver notificaciones y actualizar tu información personal.</li>
                </ul>

                <h4>1. Panel de Inicio</h4>
                <p>Al iniciar sesión, verás tu información y las opciones disponibles:</p>
                <ol>
                    <li><strong>Menú lateral:</strong> acceso a solicitudes de permiso, autoevaluaciones y perfil.</li>
                    <li><strong>Historial de permisos:</strong> consulta de permisos previos y su estado.</li>
                    <li><strong>Autoevaluación:</strong> completa tu evaluación personal según el período asignado.</li>
                </ol>

                <h4>2. Solicitud de Permisos</h4>
                <p>Para registrar un permiso:</p>
                <ol>
                    <li>Selecciona el tipo de permiso (vacaciones, enfermedad, etc.).</li>
                    <li>Indica si son días completos o si necesitas solicitar horas.</li>
                    <li>Completa la justificación y, si aplica, adjunta el documento de respaldo.</li>
                    <li>Haz clic en “Enviar” para que el sistema notifique al supervisor.</li>
                </ol>

                <h4>3. Autoevaluaciones</h4>
                <p>Podrás completar tu evaluación personal cada cierto periodo (mensual, trimestral, etc.). 
                Ingresa tus respuestas y puntajes para cada criterio.</p>
            </div>
        </asp:Panel>

        <!-- Panel para Rol Supervisor -->
        <asp:Panel ID="panelSupervisor" runat="server" Visible="false" CssClass="card mb-4">
            <div class="card-header">
                <h3 class="mb-0">Manual de Usuario - Rol Supervisor</h3>
            </div>
            <div class="card-body">
                <p>El perfil <strong>Supervisor</strong> permite aprobar o rechazar permisos de los empleados 
                bajo tu cargo, así como evaluar su desempeño.</p>

                <h4>1. Gestión de Permisos</h4>
                <ol>
                    <li><strong>Revisar solicitudes pendientes:</strong> en la sección “Gestión de Permisos” 
                        podrás ver una lista de solicitudes en estado pendiente.</li>
                    <li><strong>Aprobar/Rechazar:</strong> ingresa un comentario si rechazas la solicitud.</li>
                    <li><strong>Historial:</strong> consulta solicitudes previas, su fecha y estado.</li>
                </ol>

                <h4>2. Evaluación de Empleados</h4>
                <ol>
                    <li><strong>Evaluar personal:</strong> una vez que el empleado ha realizado su autoevaluación, 
                        podrás completar la evaluación desde tu rol de supervisor.</li>
                    <li><strong>Lista de empleados:</strong> selecciona el colaborador y periodo a evaluar.</li>
                    <li><strong>Puntajes y observaciones:</strong> asigna calificaciones y justifica cada una 
                        para llevar un registro detallado.</li>
                </ol>
            </div>
        </asp:Panel>

        <!-- Panel para Rol Recursos Humanos (RH) -->
        <asp:Panel ID="panelRH" runat="server" Visible="false" CssClass="card mb-4">
            <div class="card-header">
                <h3 class="mb-0">Manual de Usuario - Rol Recursos Humanos (RH)</h3>
            </div>
            <div class="card-body">
                <p>El perfil <strong>RH</strong> gestiona empleados, tipos de permiso, reportes y anuncios, 
                además de tener acceso para aprobar permisos y ver evaluaciones.</p>

                <h4>1. Anuncios</h4>
                <p>Puedes crear y modificar anuncios que se mostrarán como banner en la página de inicio 
                para todos los usuarios.</p>

                <h4>2. Dashboard y Reportes</h4>
                <p>Visualiza gráficos y reportes sobre empleados, evaluaciones y permisos, para un análisis 
                global del recurso humano.</p>

                <h4>3. Administración de Empleados y Departamentos</h4>
                <ol>
                    <li><strong>Crear Empleado:</strong> ingresa los datos personales, asigna departamento y 
                        tipo de empleado (interno o externo).</li>
                    <li><strong>Crear Departamento:</strong> define el nombre y supervisor del área. 
                        Luego podrás asignar empleados a dicho departamento.</li>
                </ol>

                <h4>4. Administración de Tipos de Permiso</h4>
                <p>Agrega o edita los permisos disponibles (vacaciones, maternidad, enfermedad, etc.), 
                estableciendo los días máximos anuales o mensuales y si requieren documento adjunto.</p>
            </div>
        </asp:Panel>

        <!-- Panel para Rol Administrador -->
        <asp:Panel ID="panelAdmin" runat="server" Visible="false" CssClass="card mb-4">
            <div class="card-header">
                <h3 class="mb-0">Manual de Usuario - Rol Administrador</h3>
            </div>
            <div class="card-body">
                <p>El perfil <strong>Administrador</strong> tiene acceso a todos los módulos y 
                funcionalidades, incluyendo la creación de usuarios y la configuración global del sistema.</p>

                <h4>1. Gestión de Usuarios</h4>
                <ol>
                    <li>Crear nuevos usuarios (una vez que RH haya creado al empleado).</li>
                    <li>Asignar roles (admin, rh, supervisor, empleado) y credenciales de acceso.</li>
                    <li>Activar, inactivar o eliminar usuarios según sea necesario.</li>
                </ol>

                <h4>2. Configuración de Evaluaciones</h4>
                <ol>
                    <li>Definir los periodos (trimestres, semestres, etc.) con fecha de inicio y fin.</li>
                    <li>Crear preguntas y asignarlas a un periodo, categorizándolas (Desempeño, 
                        Cumplimiento, etc.).</li>
                </ol>

                <h4>3. Auditoría</h4>
                <p>Consulta todos los registros de inserción, actualización o eliminación (INSERT, UPDATE, 
                DELETE) en tablas clave como Anuncios, Usuarios, Permisos, Empleados, etc.</p>

                <p><strong>Nota:</strong> El rol administrador es el único que puede eliminar permanentemente 
                registros.</p>
            </div>
        </asp:Panel>

        <!-- Botón para descargar el PDF del manual completo -->
        <div class="mb-3">
            <asp:HyperLink ID="hlDescargarPDF" runat="server"
                NavigateUrl="~/Docs/Manual de Usuario.pdf"
                Text="Descargar PDF - Manual de roles HonduHR"
                Target="_blank"
                CssClass="btn btn-secondary" />
        </div>

    </div>

</asp:Content>
<asp:Content ID="Content3" ContentPlaceHolderID="ScriptsContent" runat="server">
</asp:Content>
