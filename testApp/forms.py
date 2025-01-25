from django import forms
from testApp.models import ARTICLE_STATUS
from testApp.models import Article

# File referring to html forms and what user will see.

class CreateArticleForm(forms.Form):

    title = forms.CharField(max_length=100)
    status = forms.ChoiceField(choices=ARTICLE_STATUS)
    content = forms.CharField(widget=forms.Textarea)
    word_count = forms.IntegerField()
    twitter_post = forms.CharField(widget=forms.Textarea, required=False)

# How to use ModelForm instead of copying all fields manually.
#    
# class CreateArticleForm1(forms.ModelForm):
#     class Meta:
#         model = Article
#         fields = ("title", "status", "content", "word_count", "twitter_post")