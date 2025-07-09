const fs = require('fs');
const nunjucks = require('nunjucks');

try {
    nunjucks.configure('/', { autoescape: false });

    const templateName = 'import.load.tpl';
    const envVars = process.env;
    const rendered = nunjucks.render(templateName, envVars);

    fs.writeFileSync('/import.load', rendered, 'utf8');

    console.log('Шаблон успешно сгенерирован');
} catch (error) {
    console.error('Ошибка при генерации шаблона:', error.message);
    process.exit(1);
}
