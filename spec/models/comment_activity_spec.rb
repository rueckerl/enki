require File.dirname(__FILE__) + '/../spec_helper'

describe CommentActivity, '#comments' do

  def valid_comment_attributes(extra = {})
    {
      :author       => 'Don Alias',
      :author_url   => "me",
      :author_email => "me@fake.com",
      :body         => 'This is a comment',
      :post         => Post.create!(:title => 'My Post', :body => "body", :tag_list => "ruby")
    }.merge(extra)
  end

  context "find recent comments" do
    before :each do
      @comments = []
      (1..10).each do |n|
        @comments << Comment.create!(valid_comment_attributes(:created_at => Time.now - n * (60 * 60 * 24)))
      end
    end

    it "should have the comment activity sorted by when they were created" do
      comment_activity = CommentActivity.find_recent
      expect(comment_activity.first.post).to eq(@comments.first.post)
    end

    it do
      comment_activity = CommentActivity.find_recent
      expect(comment_activity).to have_exactly(5).posts
    end

    it "should not return repeated posts" do
      comment = Comment.create! valid_comment_attributes(:post => Post.first, :created_at => Time.now)
      comment_activity = CommentActivity.find_recent
      expect(comment_activity.select{|a| a.post == comment.post}.size).to eq(1)
    end

  end

  it 'finds the 5 most recent approved comments for the post' do
    ret = [mock_model(Comment)]
    comments = []
    expect(comments).to receive(:find_recent).with(hash_including(:limit => 5)).and_return(ret)
    post = mock_model(Post)
    allow(post).to receive(:approved_comments).and_return(comments)
    expect(CommentActivity.new(post).comments).to eq(ret)
  end

  it 'is memoized to avoid excess hits to the DB' do
    post = mock_model(Post)
    activity = CommentActivity.new(post)

    expect(post).to receive(:approved_comments).once.and_return(double('stub').as_null_object)
    2.times { activity.comments }
  end
end
