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
values = st.slider('Select a range of magnitudes, you want to display',1.0, 10.0, (1.0, 10.0))


def generate_map():
    eq = Earthquakes()

    ######## TO BE ALTERED FOR PRODUCTION
    eq.pulled_data = [{'id': 'e73979a9-f7aa-4b90-9a68-493146537687', 
                       'data': {'date': '2023-07-22', 'depth': 69, 'latitude': -29.61, 'magnitude': 2.9, 
                                'time': '08:21:00', 'uuid': 'e73979a9-f7aa-4b90-9a68-493146537687', 'longitude': -71.29}},
                                {'id': 'e73979a9-f7aa-4b90-9a68-493146537687', 
                       'data': {'date': '2023-07-22', 'depth': 69, 'latitude': 0, 'magnitude': 9, 
                                'time': '08:21:00', 'uuid': 'e73979a9-f7aa-4b90-9a68-493146537687', 'longitude': 0}}]
    ######## END - TO BE ALTERED FOR PRODUCTION
    filtered_data = [entry for entry in eq.pulled_data if values[0] <= entry['data']['magnitude'] <= values[1]]
    eq.pulled_data = filtered_data

    return eq.generate_map()

st.plotly_chart(generate_map())