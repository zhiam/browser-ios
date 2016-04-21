#!/usr/bin/env python
# This is the insanity that is required to modify the project to our needs
# Modifies the original project and writes a new one called Brave.xcodeproj
import sys
import os

sys.path.insert(0, os.path.abspath('./build-system'))
from mod_pbxproj import XcodeProject, PBXBuildFile, PBXFileReference


proj_file = '../Client.xcodeproj/project.pbxproj'
tmp_proj_file = '/tmp/project.pbxproj'

try:
    os.remove(proj_file)
except:
    pass

# use backslash to unalias cp
os.system('\\cp -f ../Client.xcodeproj.tgz /tmp; cd /tmp; tar xzf Client*tgz; cd -; ' +
          'rsync -ar /tmp/Client.xcodeproj/* ../Client.xcodeproj')

fabric_keys = None
try:
    key_path = os.path.expanduser('~/.brave-fabric-keys')
    with open(key_path) as f:
        fabric_keys = [x.strip() for x in f.readlines()]
    os.system(
        "sed -e 's/FABRIC_KEY_REMOVED/" + fabric_keys[0] + "/' ../Client/Info.plist.template > ../Client/Info.plist")
    os.system("> xcconfig/.fabric-override.xcconfig")
except:
    print 'no fabric keys'
    os.system("\\cp -f ../Client/Info.plist.template ../Client/Info.plist")
    os.system("echo 'OTHER_SWIFT_FLAGS = -DBRAVE -DDEBUG -DNO_FABRIC' > xcconfig/.fabric-override.xcconfig")

bundle_id = open("xcconfig/.bundle-id.xcconfig").readline().rstrip()
bundle_id = bundle_id[bundle_id.find('=') + 1:].strip()
os.system("sed -i '' -e 's/BUNDLE-ID-PLACEHOLDER/" + bundle_id + "/' ../Client/Info.plist")

cached_path_to_group = {}
cached_filepath_to_item = {}

def add_dir_as_group(project, directory_path):
    directory_path = directory_path.replace('../','')
    if directory_path in cached_path_to_group:
        return cached_path_to_group[directory_path]
    parent_dir = os.path.dirname(directory_path)
    group = None
    if parent_dir:
        group = add_dir_as_group(project=project, directory_path=parent_dir)
    group = project.get_or_create_group(os.path.basename(directory_path), path=directory_path, parent=group)
    cached_path_to_group[directory_path] = group
    return group


def add_build_files(project, target_name, file_name):
    # add shared
    shared_files = open(file_name)
    lines = [line.rstrip('\n') for line in shared_files]
    for line in lines:
        # project.add_file(line, tree="<group>", target=target_name, create_build_files=True, ignore_unknown_type=True)
        file_ref = None
        if not line in cached_filepath_to_item:
            print("cached_filepath_to_item missing:" + line)
            file_ref = project.add_file(line, tree="<group>", create_build_files=False, ignore_unknown_type=True)[0]

        if not file_ref:
            file_ref = cached_filepath_to_item[line]
        if not isinstance(file_ref, PBXFileReference):
            continue

        if file_ref.build_phase:
            phases = project.get_build_phases(file_ref.build_phase)
            target = project.get_target_by_name(target_name)
            assert(target)
            for phase in phases:
                if phase.id in target.get('buildPhases'):
                    build_file = PBXBuildFile.Create(file_ref)
                    phase.add_build_file(build_file)
                    project.objects[build_file.id] = build_file



def add_file(project, file, parent):
    item = project.add_file(file, parent=parent, tree="<group>", create_build_files=False, ignore_unknown_type=True)
    full_path = parent['path'] + '/' + file if 'path' in parent else file
    if full_path in cached_filepath_to_item:
        print('Duplicate file in add_file: ' + full_path + ' item:' + str(item))
    else:
        cached_filepath_to_item[full_path] = item[0]


def add_project_files(project, root_dir_list):

    for root_dir in root_dir_list:
        add_dir_as_group(project, root_dir)
        for root, subfolders, files in os.walk('../' + root_dir):
            if 'SearchPlugins' in root:
                continue

            for folder in subfolders:
                if any(x in folder for x in ['.xcassets']) or folder == 'SearchPlugins':
                    if not 'Client' in root:
                        continue
                    parent = add_dir_as_group(project, root)
                    # add_file(project, file=folder, parent=parent)
                    project.add_file(folder, parent=parent, tree="<group>", target='Client', create_build_files=True, ignore_unknown_type=True)
                else:
                    add_dir_as_group(project, root + '/' + folder)

            for file in files:
                if any(file.endswith(x) for x in ['.h', '.swift', '.m', '.mm', '.entitlements',  '.plist']):
                    parent = add_dir_as_group(project, root)
                    add_file(project, file=file, parent=parent)
                elif any(file.endswith(x) for x in ['.js', '.txt', '.html']):
                    if not 'Client' in root:
                        print('ignore: ' + root + '/' + file)
                        continue
                    parent = add_dir_as_group(project, root)
                    project.add_file(file, parent=parent, tree="<group>", target='Client', create_build_files=True, ignore_unknown_type=True)

    for target in ['Account', 'BraveShareTo', 'Client', 'ReadingList', 'Shared', 'Storage', 'Sync']:
        add_build_files(project, target, 'build-system/target-' + target + '.txt')

def add_brave_files(project):
    if fabric_keys:
        project.add_run_script(target='Client',
                               script='./Fabric.framework/run ' + fabric_keys[0] + ' ' + fabric_keys[1])

    topgroup = project.get_or_create_group('brave', path='brave')
    group = project.get_or_create_group('src', path='brave/src', parent=topgroup)
    groups = {'brave/src': group}
    project.add_file('brave/Brave.entitlements', parent=topgroup, ignore_unknown_type=True)

    for root, subfolders, files in os.walk('src'):
        for folder in subfolders:
            g = project.get_or_create_group(folder, path='brave/' + root + '/' + folder, parent=group)
            groups['brave/' + root + '/' + folder] = g
        for file in files:
            if any(file.endswith(x) for x in ['.h', '.js', '.swift', '.m', '.mm', '.html', '.entitlements']):
                p = groups['brave/' + root]
                if 'test' in root:
                    # add only to the test target
                    project.add_file(file, parent=p, tree="<group>", target='ClientTests', ignore_unknown_type=True)
                    continue

                build_files = project.add_file(file, parent=p, tree="<group>", target='Client',
                                               ignore_unknown_type=True)

                # This is the (crappy) method of listing files that aren't added to ClientTests
                filename_substrings_not_for_clienttest = ['Setting.swift']
                if 'frontend' in root or 'page-hooks' in root or file.endswith('.js') or any(
                                substring in file for substring in filename_substrings_not_for_clienttest):
                    continue

                # from here on, add file to test target (this is in addition to the Client target)
                def add_build_file_to_target(file, target_name):
                    target = project.get_target_by_name(target_name)
                    phases = target.get('buildPhases')
                    # phases = project.get_build_phases('PBXSourcesBuildPhase')
                    find = phases[0]
                    result = [p for p in project.objects.values() if p.id == find]
                    list = result[0].data['files']
                    list.data.append(file.id)

                for b in build_files:
                    if b['isa'] == 'PBXBuildFile':
                        add_build_file_to_target(b, 'ClientTests')

    group = project.get_or_create_group('abp-filter-parser-cpp', path='brave/node_modules/abp-filter-parser-cpp',
                                        parent=topgroup)
    for f in ['ABPFilterParser.h', 'ABPFilterParser.cpp', 'filter.cpp',
              'node_modules/bloom-filter-cpp/BloomFilter.cpp', 'node_modules/bloom-filter-cpp/BloomFilter.h',
              'node_modules/hashset-cpp/hashFn.h', 'node_modules/hashset-cpp/HashItem.h',
              'node_modules/hashset-cpp/HashSet.h', 'node_modules/hashset-cpp/HashSet.cpp',
              'cosmeticFilter.h', 'cosmeticFilter.cpp']:
        project.add_file(f, parent=group, tree="<group>", target='Client', ignore_unknown_type=True)

    group = project.get_or_create_group('tracking-protection', path='brave/node_modules/tracking-protection',
                                        parent=topgroup)
    for f in ['FirstPartyHost.h', 'TPParser.h', 'TPParser.cpp']:
        project.add_file(f, parent=group, tree="<group>", target='Client', ignore_unknown_type=True)

    arr = project.root_group.data['children'].data
    arr.insert(0, arr.pop())

    if fabric_keys:
        project.add_file('Fabric.framework', target='Client')
        project.add_file('Crashlytics.framework', target='Client')

    configs = [p for p in project.objects.values() if p.get('isa') == 'XCBuildConfiguration']
    for i in configs:
        build_settings = i.data['buildSettings']
        if 'PRODUCT_BUNDLE_IDENTIFIER' in build_settings:
            if 'PRODUCT_NAME' in build_settings and 'Client' in build_settings['PRODUCT_NAME']:
                build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = bundle_id
            else:
                build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = bundle_id + '.$(PRODUCT_NAME)'
        elif 'INFOPLIST_FILE' in build_settings:
            build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = bundle_id + '.$(PRODUCT_NAME)'


pbxHeaderSection = []  # save this and restore it later
pbxHeaderSection_parsing = False
out_lines = []
prev_line = None
infile = open(proj_file, 'r')
line = infile.readline()
while line:
    if 'PBXHeadersBuildPhase section' in line:
        pbxHeaderSection_parsing = not pbxHeaderSection_parsing

    if pbxHeaderSection_parsing:
        pbxHeaderSection.append(line)

    out_lines.append(line)

    prev_line = line
    line = infile.readline()

infile.close()

outfile = open(tmp_proj_file, 'w')
for line in out_lines:
    outfile.write("%s\n" % line)
outfile.close()
from shutil import move

move(tmp_proj_file, proj_file)

project = XcodeProject.Load(proj_file)
add_project_files(project, ['Account', 'BraveShareTo', 'Client', 'FxA', 'FxAClient', 'Providers',
      'ReadingList', 'Shared', 'Storage', 'Sync', 'ThirdParty', 'Utils'])
add_brave_files(project)
project.save()


## put back missing section due to bug
def put_back_missing_section(missingSection):
    infile = open(proj_file, 'r')
    outfile = open(tmp_proj_file, 'w')
    line = infile.readline()
    while line:
        # pick an arbitrary safe spot in the file
        if 'Begin PBXBuildFile section' in line and missingSection != None:
            for i in missingSection:
                outfile.write(i)
            missingSection = None
        outfile.write(line)
        line = infile.readline()

    infile.close()
    outfile.close()
    move(tmp_proj_file, proj_file)


put_back_missing_section(pbxHeaderSection)
