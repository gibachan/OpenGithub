def detect_project_root(path)
    path = File.dirname(path)
    
    if Dir.glob(File.join(path, ".git")).count > 0
        return path
    end
    
    return nil if path == "/"
    detect_project_root(path)
end

full_path = `osascript<<END
    tell application "Xcode"
        set file_name to name of front window
        set file_name to replace(file_name, " — Edited", "") of me

        set num to number of source document

        repeat with index from 0 to num
            set file_path to path of source document index
            set pos to offset of file_name in file_path

            if pos is greater than 0 then
                return file_path
            end if
        end repeat
    end tell

    on replace(orgStr, tgtStr, newStr)

    local orgDelim, rtn

    set orgDelim to AppleScript's text item delimiters
    set AppleScript's text item delimiters to {tgtStr}
    set rtn to every text item of orgStr
    set AppleScript's text item delimiters to {newStr}
    set rtn to rtn as string
    set AppleScript's text item delimiters to orgDelim
    return rtn

    end replace
END`.strip

project_root = detect_project_root(full_path)
file_path = full_path.sub("#{project_root}/", '')

line = ARGV[0] || 1
repository = nil
branch = nil
commit_hash = nil
pr_number = nil
Dir.chdir project_root do
    `git remote -v`.strip.lines do |line|
        if line =~ %r{git@github.com:(.+)\.git \(fetch\)$} || line =~ %r{https://github.com/(.+) \(fetch\)$}
            repository = $1
            break
        end
    end
    exit unless repository
    
    `git branch -r`.strip.lines do |line|
        if line =~ %r{.+/HEAD -> .+/(.+)$}
            branch = $1
            break
        end
    end
    exit unless branch
    
    `git blame #{file_path} | sed -n "#{line}p"`.strip.lines do |line|
        if line =~ %r{^([a-z0-9]+)}
            commit_hash = $1
            break
        end
    end
    exit unless commit_hash
    
    `git log --merges --oneline --reverse --ancestry-path #{commit_hash}...#{branch}`.strip.lines do |line|
        if line =~ %r{.+Merge pull request #(\d+)}
            pr_number = $1
            break
        end
    end
    exit unless pr_number
end

system "open 'https://github.com/#{repository}/pull/#{pr_number}'"
