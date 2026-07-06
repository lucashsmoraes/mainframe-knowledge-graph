"""Interface Streamlit para o Mainframe Knowledge Graph Chat."""

import streamlit as st
from graphrag_chain import ask

st.set_page_config(
    page_title="Mainframe Knowledge Graph",
    page_icon="🏢",
    layout="wide",
)

st.title("🏢 Mainframe Knowledge Graph — Chat")
st.caption("Pergunte sobre programas COBOL, tabelas, consumidores e impactos")

# Sidebar com exemplos
with st.sidebar:
    st.header("💡 Exemplos de perguntas")
    exemplos = [
        "Qual o impacto de alterar a tabela TB_CLIENTE?",
        "Quais sistemas consomem o programa PGMCLI01?",
        "Quais são os consumidores de alta criticidade?",
        "Quais tabelas o programa PGMFAT02 acessa?",
        "Me explique a regra de cálculo de juros",
        "Qual a cadeia de dependências do PGMLOG01?",
    ]
    for ex in exemplos:
        if st.button(ex, use_container_width=True):
            st.session_state.question = ex

# Chat
if "messages" not in st.session_state:
    st.session_state.messages = []

for msg in st.session_state.messages:
    with st.chat_message(msg["role"]):
        st.markdown(msg["content"])

question = st.chat_input("Faça uma pergunta sobre o mainframe...")

if "question" in st.session_state:
    question = st.session_state.pop("question")

if question:
    st.session_state.messages.append({"role": "user", "content": question})
    with st.chat_message("user"):
        st.markdown(question)

    with st.chat_message("assistant"):
        with st.spinner("Consultando grafo e documentações..."):
            response = ask(question)
        st.markdown(response)

    st.session_state.messages.append({"role": "assistant", "content": response})
