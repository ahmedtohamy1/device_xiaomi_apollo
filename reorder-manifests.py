import xml.etree.ElementTree as ET
import os
import glob

def get_name(element):
    name_element = element.find('.//name')
    return name_element.text if name_element is not None else ""

def sort_xml_file(file_path):
    tree = ET.parse(file_path)
    root = tree.getroot()
    
    sorted_entries = sorted(root.findall('.//hal'), key=get_name)
    
    root[:] = sorted_entries
    tree.write(file_path)
    print(f"Sorted and updated: {file_path}")

# List of target file names
target_files = ['manifest.xml', 'framework_compatibility_matrix.xml', 'compatibility_matrix.xml']

for target_file in target_files:
    for file_path in glob.iglob(f'**/{target_file}', recursive=True):
        sort_xml_file(file_path)

