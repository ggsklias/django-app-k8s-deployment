from django.urls import path
from ArticleApp.views import ArticleCreateView, ArticleListView, ArticleUpdateView, ArticleDeleteView



urlpatterns = [
    # The name attribute is connected with the templates tag url
    
    path("", ArticleListView.as_view(), name="home"),
    # with slash even if the user visits articles/create/ it works
    path("create/", ArticleCreateView.as_view(), name="create_article"),
    path("<int:pk>/update", ArticleUpdateView.as_view(), name="update_article"),
    path("<int:pk>/delete", ArticleDeleteView.as_view(), name="delete_article"),
]
