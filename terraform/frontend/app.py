import streamlit as st
from earthquakes import Earthquakes

page_bg_img = """
<style>
[data-testid="stAppViewContainer"] {
background-color: #f2efe9
}
</style>
"""

st.set_page_config(page_title="Earthquake Streaming", layout="wide")
st.markdown(page_bg_img, unsafe_allow_html=True)
st.markdown('<h1 style="color: black;">Earthquake Streaming</h1>', unsafe_allow_html=True)
st.markdown('<h1 style="color: black; font-size: 14px;">This dashboard visualizes global earthquakes in near-real time. To get new earthquakes, please refresh the page.</h1>', unsafe_allow_html=True)

st.markdown(
        """<style>
    div[class*="stSlider"] > label > div[data-testid="stMarkdownContainer"] > p {
        font-size: 14px;
        color: black;
        font-weight: bold;
    }
        </style>
        """, unsafe_allow_html=True)

def generate_map():
    eq = Earthquakes()

    return eq.generate_map()

st.plotly_chart(generate_map())
