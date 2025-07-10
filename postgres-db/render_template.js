const fs = require('fs');
const nunjucks = require('nunjucks');

try {
    nunjucks.configure('/', { autoescape: false });

    const templateName = process.argv[2];
    if (!templateName) {
        throw new Error('Не указан шаблон в аргументе. Пример: node render_template.js import.load.tpl');
    }

    if (!fs.existsSync('/' + templateName)) {
        throw new Error(`Шаблон не найден: ${templateName}`);
    }

    const envVars = process.env;
    const rendered = nunjucks.render(templateName, envVars);

    // Записываем в /import.load независимо от шаблона
    fs.writeFileSync('/import.load', rendered, 'utf8');

    console.log(`✅ Сгенерирован /import.load из шаблона ${templateName}`);
} catch (error) {
    console.error('❌ Ошибка при генерации шаблона:', error.message);
    process.exit(1);
}
