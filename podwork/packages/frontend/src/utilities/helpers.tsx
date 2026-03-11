import { SUB_CATEGORY_DATA } from './sub_categories';
import { DATA_SOURCE } from './main_categories';

// pass in the active categories
export const getSlideClass = (activeCategory: string | null, activeSubCategory: string | null) => {
    if (activeSubCategory) return 'level-3';
    if (activeCategory) return 'level-2';
    return '';    
};

// pass in the selectedIds array
export const getSelectedNames = (selectedIds: string[]) => {
    const subCategoryNames: string[] = [];
    const weatherNames: string[] = [];
    
    Object.values(SUB_CATEGORY_DATA).forEach(element => {
      element.forEach((item) => {
        if (selectedIds.includes(item.id)){
          subCategoryNames.push(item.id);
        }
      })
    });

    Object.values(DATA_SOURCE['Weather']).forEach(element => {
        if (selectedIds.includes(element.id)){
          weatherNames.push(element.id);
        }
    });

    return { subCategoryNames, weatherNames };
};

export const fetchAndParseInterestsXML = async () => {
  try {
    // get the data
    const response = await fetch('/interest_data.xml');
    const xmlText = await response.text();

    // conver text into readable xml document
    const parser = new DOMParser();
    const xmlDoc = parser.parseFromString(xmlText, 'text/xml');

    // build data structure
    const parsedData: Record<string, { id: string }[]> = {};

    // loop through each category
    const categories = xmlDoc.getElementsByTagName('category');
    for (let i = 0; i < categories.length; i++) {
      const category = categories[i];
      const categoryName = category.getAttribute('name');
      
      if (!categoryName) continue;

      const itemsList = [];
      const items = category.getElementsByTagName('item');
      
      // loop through each item
      for (let j = 0; j < items.length; j++) {
        const idNode = items[j].getElementsByTagName('id')[0];
        if (idNode && idNode.textContent) {
          itemsList.push({ id: idNode.textContent });
        }
      }

      parsedData[categoryName] = itemsList;
    }

    return parsedData;
  } catch (error) {
    console.error("Failed to load or parse interest_data.xml:", error);
    return {};
  }
};