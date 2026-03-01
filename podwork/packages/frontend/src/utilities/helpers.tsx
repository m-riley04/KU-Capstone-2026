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