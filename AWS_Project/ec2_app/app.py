import streamlit as st
import requests
import os
import json

# Configuración de la página
st.set_page_config(
    page_title="Dashboard de Productos",
    page_icon="📦",
    layout="wide"
)

# URL del API Gateway (se debe configurar como variable de entorno)
API_URL = os.environ.get('API_GATEWAY_URL', 'https://your-api-gateway-url.amazonaws.com/prod')

def get_all_products():
    """Obtener todos los productos"""
    try:
        response = requests.get(f"{API_URL}/products")
        if response.status_code == 200:
            return response.json().get('products', [])
        return []
    except Exception as e:
        st.error(f"Error al obtener productos: {str(e)}")
        return []

def create_product(product_data):
    """Crear un nuevo producto"""
    try:
        response = requests.post(f"{API_URL}/products", json=product_data)
        return response.status_code == 201
    except Exception as e:
        st.error(f"Error al crear producto: {str(e)}")
        return False

def update_product(product_id, product_data):
    """Actualizar un producto"""
    try:
        response = requests.put(f"{API_URL}/products/{product_id}", json=product_data)
        return response.status_code == 200
    except Exception as e:
        st.error(f"Error al actualizar producto: {str(e)}")
        return False

def delete_product(product_id):
    """Eliminar un producto"""
    try:
        response = requests.delete(f"{API_URL}/products/{product_id}")
        return response.status_code == 200
    except Exception as e:
        st.error(f"Error al eliminar producto: {str(e)}")
        return False

# Título principal
st.title("📦 Sistema de Gestión de Productos")
st.markdown("---")

# Sidebar para crear productos
with st.sidebar:
    st.header("➕ Crear Nuevo Producto")
    
    with st.form("create_form"):
        new_id = st.text_input("ID del Producto", key="new_id")
        new_name = st.text_input("Nombre", key="new_name")
        new_description = st.text_area("Descripción", key="new_description")
        new_price = st.number_input("Precio", min_value=0.0, step=0.01, key="new_price")
        new_stock = st.number_input("Stock", min_value=0, step=1, key="new_stock")
        
        submit = st.form_submit_button("Crear Producto")
        
        if submit:
            if new_id and new_name:
                product_data = {
                    "id": new_id,
                    "name": new_name,
                    "description": new_description,
                    "price": float(new_price),
                    "stock": int(new_stock)
                }
                
                if create_product(product_data):
                    st.success("✅ Producto creado exitosamente")
                    st.rerun()
                else:
                    st.error("❌ Error al crear el producto")
            else:
                st.warning("⚠️ ID y Nombre son obligatorios")

# Botón para refrescar
col1, col2 = st.columns([6, 1])
with col2:
    if st.button("🔄 Refrescar"):
        st.rerun()

# Obtener y mostrar productos
products = get_all_products()

if products:
    st.subheader(f"Total de Productos: {len(products)}")
    
    # Mostrar productos en una tabla
    for product in products:
        with st.expander(f"🏷️ {product.get('name', 'Sin nombre')} (ID: {product.get('id', 'N/A')})"):
            col1, col2, col3 = st.columns([2, 2, 1])
            
            with col1:
                st.write(f"**Descripción:** {product.get('description', 'Sin descripción')}")
                st.write(f"**Precio:** ${product.get('price', 0):.2f}")
                st.write(f"**Stock:** {product.get('stock', 0)} unidades")
            
            with col2:
                st.write(f"**Creado:** {product.get('created_at', 'N/A')}")
                st.write(f"**Actualizado:** {product.get('updated_at', 'N/A')}")
            
            with col3:
                # Botón para editar
                if st.button("✏️ Editar", key=f"edit_{product['id']}"):
                    st.session_state[f"editing_{product['id']}"] = True
                
                # Botón para eliminar
                if st.button("🗑️ Eliminar", key=f"delete_{product['id']}"):
                    if delete_product(product['id']):
                        st.success("Producto eliminado")
                        st.rerun()
            
            # Formulario de edición
            if st.session_state.get(f"editing_{product['id']}", False):
                with st.form(f"edit_form_{product['id']}"):
                    edit_name = st.text_input("Nombre", value=product.get('name', ''))
                    edit_description = st.text_area("Descripción", value=product.get('description', ''))
                    edit_price = st.number_input("Precio", value=float(product.get('price', 0)), min_value=0.0, step=0.01)
                    edit_stock = st.number_input("Stock", value=int(product.get('stock', 0)), min_value=0, step=1)
                    
                    col_submit, col_cancel = st.columns(2)
                    with col_submit:
                        submit_edit = st.form_submit_button("💾 Guardar")
                    with col_cancel:
                        cancel_edit = st.form_submit_button("❌ Cancelar")
                    
                    if submit_edit:
                        update_data = {
                            "name": edit_name,
                            "description": edit_description,
                            "price": float(edit_price),
                            "stock": int(edit_stock)
                        }
                        
                        if update_product(product['id'], update_data):
                            st.success("Producto actualizado")
                            st.session_state[f"editing_{product['id']}"] = False
                            st.rerun()
                    
                    if cancel_edit:
                        st.session_state[f"editing_{product['id']}"] = False
                        st.rerun()
else:
    st.info("📭 No hay productos disponibles. Crea uno usando el formulario en la barra lateral.")

# Footer
st.markdown("---")
st.markdown("🚀 **Dashboard desplegado en EC2 | API en Lambda | Datos en DynamoDB**")
