import pandas as pd
import plotly.express as px
import plotly.io as pio
from plotly.graph_objects import Figure

import connection

class Earthquakes:

    __pulled_data = None
    __data = None
    __map = None

    @property
    def pulled_data(self) -> list:
        return self.__pulled_data

    @property
    def data(self) -> pd.DataFrame:
        return self.__data

    @property
    def map(self) -> Figure:
        return self.__map

    @pulled_data.setter
    def pulled_data(self, data: list) -> None:
        if (isinstance(data, list)):
            self.__pulled_data = data
        else:
            raise TypeError(f"{self.__class__.__name__}.__pulled_data only supports lists")

    @data.setter
    def data(self, data: pd.DataFrame) -> None:
        if data.__class__.__name__ == "DataFrame" and data.__module__ == "pandas.core.frame":
            self.__data = data
        else:
            raise TypeError(f"{self.__class__.__name__}.__data only supports pandas DataFrames")

    @map.setter
    def map(self, map: Figure) -> None:
        if map.__module__ == 'plotly.graph_objs._figure' and map.__class__.__name__ == "Figure":
            self.__map = map
        else:
            raise TypeError(f"{self.__class__.__name__}.__map only supports plotly Figure objects")


    def pull_data(self, table_name: str = "eartquakes"):
        pulled = connection.scan_table(table_name)
        pulled = list(pulled['Items'])
        try:
            self.pulled_data = pulled
            return pulled
        except TypeError as error:
            raise Exception("Dynamo did not return the correct data type - " + str(error))


    def __transform_core(self, input_data: list) -> pd.DataFrame:
        data = pd.DataFrame(columns=["id", "depth", "latitude", "magnitude", "time", "uuid", "longitude"])
        for index, entry in enumerate(input_data):
            data.loc[index, "id"] = entry["id"]
            details = entry["data"]
            for key in details.keys():
                data.loc[index, key] = details[key]
        return data

    def transform_data(self) -> pd.DataFrame:
        if self.pulled_data is None:
            self.pulled_data = self.pull_data()
            print("data pulled on default table")
        data = self.__transform_core(self.pulled_data)
        self.data = data
        return data

    def __generate_core(self, data: pd.DataFrame, m_size: int = 10, m_color: str = "red", width: int = 1300, height: int = 900) -> Figure:
        fig = px.scatter_mapbox(data_frame = data,
                                lat='latitude',
                                lon='longitude',
                                mapbox_style="open-street-map",
                                hover_name='id',
                                hover_data=["magnitude", "depth"],
                                zoom = 1.5,
                                width = width,
                                height = height)
        fig.update_traces(marker = dict(size = m_size, color = m_color))
        fig.update_layout(margin = {"r":0,"t":0,"l":0,"b":0})
        return fig

    def generate_map(self, m_size: int = 10, m_color: str = "blue") -> Figure:
        if self.data is None:
            self.data = self.transform_data()
        fig = self.__generate_core(self.data)
        self.map = fig
        return fig
