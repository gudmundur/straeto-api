from fabric.api import env, run, local, put, cd

env.hosts = ['gulur.is']

def pushdb():
    local('mongodump -d bus -o busdump')
    local('tar cvfj busdump.tbz busdump')
    local('rm -rf busdump')

    put('busdump.tbz', '~/databases')

    with cd('databases'):
        run('tar xvfj busdump.tbz')
        run('mongorestore --drop busdump')
        run('rm -r busdump.tbz busdump')

    local('rm busdump.tbz')
