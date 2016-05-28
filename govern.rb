require 'octokit'

TOKEN = ENV.fetch('GITHUB_TOKEN')
OWNER = ENV.fetch('OWNER')

# https://developer.github.com/v3/issues/comments/#reactions-summary
# Octokit.default_media_type = 'application/vnd.github.squirrel-girl-preview'
# TODO auto-paginate

@client = Octokit::Client.new(access_token: TOKEN)

def merged_prs
  results = @client.search_issues("user:#{OWNER} is:merged -author:#{OWNER}")
  results.items
end

merged_prs_per_repo = merged_prs.group_by do |pr|
  pr.repository_url.split('/').last
end

puts "Users to promote:"
merged_prs_per_repo.each do |repo, prs|
  prs_per_user = prs.group_by { |pr| pr.user.login }
  users_to_promote = prs_per_user.keys.select { |user| prs_per_user[user].size > 1 }
  puts "#{repo}: #{users_to_promote.join(',')}"
end
