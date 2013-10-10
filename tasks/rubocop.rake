require 'rubocop/rake_task'

namespace :rubocop do
  def get_modified_files
    git_root_folder = get_git_root_folder
    return unless git_root_folder

    git_output = `git status --porcelain`
    return unless $CHILD_STATUS.success?

    file_list = parse_git_status(git_output)
    .compact
    .map { |file_path| File.join(git_root_folder, file_path) }

    filter_files(file_list)
  end

  def get_commit_files(commit_id)
    git_root_folder = get_git_root_folder
    return unless git_root_folder

    git_output = `git show --pretty="format:" --name-status #{commit_id}`
    return unless $CHILD_STATUS.success?

    file_list = parse_git_commit(git_output)
    .compact
    .map { |file_path| File.join(git_root_folder, file_path.strip) }

    filter_files(file_list)
  end

  def get_local_commit_files
    git_output = `git log --pretty="format:%h" @{u}.. 2>/dev/null`
    return unless $CHILD_STATUS.success?

    file_list = []
    git_output.each_line do |line|
      file_list.concat(get_commit_files(line.strip))
    end

    file_list
  end

  def parse_git_status(git_status)
    git_status.each_line.map do |line|
      original, renamed = line
      .scan(/^[ MARCU?!]{2} (.+?)(?: -> (.+?))?$/)
      .compact
      .flatten

      renamed ? renamed : original
    end
  end

  def parse_git_commit(git_commit)
    git_commit.each_line.map do |line|
      line
      .scan(/^[MARCU]\t(.+?)$/)
      .compact
      .flatten
      .first
    end
  end

  def get_git_root_folder
    git_to_level = `git rev-parse --show-toplevel`.strip
    return unless $CHILD_STATUS.success?

    git_to_level
  end

  def filter_files(files)
    allowed_file_ext = [".rb", ".rake"]

    files.select { |file| allowed_file_ext.include?(File.extname(file)) }
  end

  desc "Run rubocop on modified files"
  Rubocop::RakeTask.new(:modified) do |task|
    files = get_modified_files
    abort("No ruby files found") unless files && !files.empty?

    task.patterns = files
  end

  desc "Run rubocop on non-pushed commits"
  Rubocop::RakeTask.new(:local) do |task|
    files = get_local_commit_files
    abort("No ruby files found") unless files && !files.empty?

    task.patterns = files
  end

  desc "Run rubocop on files in a commit ex. rake rubocop:commit[$commit_id]"
  Rubocop::RakeTask.new(:commit, :id) do |task, args|
    files = get_commit_files(args.id)
    abort("No ruby files found") unless files && !files.empty?

    task.patterns = files
  end
end
