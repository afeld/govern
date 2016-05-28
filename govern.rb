require 'octokit'

TOKEN = ENV.fetch('GITHUB_TOKEN')

# https://developer.github.com/v3/issues/comments/#reactions-summary
# Octokit.default_media_type = 'application/vnd.github.squirrel-girl-preview'
# TODO auto-paginate

@client = Octokit::Client.new(access_token: TOKEN)
OWNER = @client.user.login

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

  users_with_multiple_merges = prs_per_user.keys.select { |user| prs_per_user[user].size > 2 }
  collaborators = @client.collaborators("#{OWNER}/#{repo}").map(&:login)
  users_to_promote = users_with_multiple_merges - collaborators

  if users_to_promote.any?
    puts "#{repo}:"
    users_to_promote.each do |user|
      puts "\t#{user}:"
      prs_per_user[user].each do |pr|
        puts "\t\t#{pr.html_url}"
      end
    end
  end
end
