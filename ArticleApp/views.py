from typing import Any

from django.db.models.query import QuerySet
from django.shortcuts import render#, redirect
from django.urls import reverse_lazy
from django.views.generic import CreateView, ListView, DeleteView, UpdateView
from ArticleApp.models import Article
from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin

#from ArticleApp.forms import CreateArticleForm

# LoginRequiredMixin protects the access to logged in users
class ArticleListView(LoginRequiredMixin, ListView):
    template_name = "ArticleApp/home.html"
    model = Article
    context_object_name = "articles"
    
    def get_queryset(self) -> QuerySet[Any]:
        return Article.objects.filter(creator=self.request.user).order_by("-created_at")

class ArticleCreateView(LoginRequiredMixin, CreateView):
    template_name = "ArticleApp/article_create.html"
    model = Article
    fields = ["title","status","content","twitter_post"]
    success_url = reverse_lazy("home")

    def form_valid(self, form):
        form.instance.creator = self.request.user
        return super().form_valid(form)
    
class ArticleUpdateView(LoginRequiredMixin, UserPassesTestMixin, UpdateView):
    template_name = "ArticleApp/article_update.html"
    model = Article
    fields = ["title","status","content","twitter_post"]
    success_url = reverse_lazy("home")
    context_object_name = "article"

    def test_func(self) -> bool | None:
        return self.request.user == self.get_object().creator

class ArticleDeleteView(LoginRequiredMixin, UserPassesTestMixin, DeleteView):
    template_name = "ArticleApp/article_delete.html"
    model = Article
    success_url = reverse_lazy("home")
    context_object_name = "article"

    def test_func(self) -> bool | None:
        return self.request.user == self.get_object().creator




# def home(request):
#     articles = Article.objects.all()
#     return render(request, "ArticleApp/home.html", {"articles": articles})

# def create_article(request):
#     if request.method == "POST":
#         form = CreateArticleForm(request.POST)
#         if form.is_valid():
#             form_data = form.cleaned_data()
#             new_article = Article(
#                 title=form_data["title"],
#                 status=form_data["status"],
#                 content=form_data["content"],
#                 word_count=form_data["word_count"],
#                 twitter_post=form_data["twitter_post"],
#             )
#             new_article.save()
#             return redirect("home")
#     else:
#         form = CreateArticleForm()
#     return render(request, "ArticleApp/article_create.html", {"form": form})