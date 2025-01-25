from django.urls import path
from testApp.views import ArticleCreateView, ArticleListView, ArticleUpdateView, ArticleDeleteView



urlpatterns = [
    path("", ArticleListView.as_view(), name="home"),
    # with slash even if the user visits articles/create/ it works
    path("create/", ArticleCreateView.as_view(), name="create_article"),
    path("<int:pk>/update", ArticleUpdateView.as_view(), name="update_article"),
    path("<int:pk>/delete", ArticleDeleteView.as_view(), name="delete_article"),
]
