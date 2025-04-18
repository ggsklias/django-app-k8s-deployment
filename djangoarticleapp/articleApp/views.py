from typing import Any

from django.db.models.query import QuerySet
from django.shortcuts import render#, redirect
from django.urls import reverse_lazy
from django.views.generic import CreateView, ListView, DeleteView, UpdateView
from articleApp.models import Article
from django.contrib.auth.mixins import LoginRequiredMixin, UserPassesTestMixin
from django.http import JsonResponse

#from articleApp.forms import CreateArticleForm

# LoginRequiredMixin protects the access to logged in users
class ArticleListView(LoginRequiredMixin, ListView):
    template_name = "articleApp/home.html"
    model = Article
    context_object_name = "articles"
    
    def get_queryset(self) -> QuerySet[Any]:
        return Article.objects.filter(creator=self.request.user).order_by("-created_at")

class ArticleCreateView(LoginRequiredMixin, CreateView):
    template_name = "articleApp/article_create.html"
    model = Article
    fields = ["title","status","content","twitter_post"]
    success_url = reverse_lazy("home")

    def form_valid(self, form):
        form.instance.creator = self.request.user
        return super().form_valid(form)
    
class ArticleUpdateView(LoginRequiredMixin, UserPassesTestMixin, UpdateView):
    template_name = "articleApp/article_update.html"
    model = Article
    fields = ["title","status","content","twitter_post"]
    success_url = reverse_lazy("home")
    context_object_name = "article"

    # enables user authorization - checks if current user is the owner of the article
    def test_func(self) -> bool | None:
        return self.request.user == self.get_object().creator

class ArticleDeleteView(LoginRequiredMixin, UserPassesTestMixin, DeleteView):
    template_name = "articleApp/article_delete.html"
    model = Article
    success_url = reverse_lazy("home")
    context_object_name = "article"

    # enables user authorization - checks if current user is the owner of the article
    def test_func(self) -> bool | None:
        return self.request.user == self.get_object().creator

def healthz(request):
    return JsonResponse({'status': 'ok'})
