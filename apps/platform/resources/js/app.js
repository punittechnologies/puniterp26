//
import Konva from 'konva';

window.labelDesigner = function labelDesigner(templateJsonText, widthMm, heightMm) {
    return {
        templateJsonText,
        templateJson: {},
        widthMm,
        heightMm,
        stage: null,
        layer: null,
        transformer: null,
        selected: null,
        selectedElement: null,
        scale: 4,
        size: '75x75',
        warnings: [],
        jsonText: '',
        history: [],
        future: [],
        historyLimit: 50,
        isApplyingHistory: false,
        activeEditSnapshot: null,
        keyboardHandler: null,
        init() {
            this.templateJson = this.parseJson(this.templateJsonText);
            this.render();
            this.remember();
            this.keyboardHandler = (event) => {
                const key = String(event.key || '').toLowerCase();
                const isModifier = event.ctrlKey || event.metaKey;
                const isFormControl = ['input', 'textarea', 'select'].includes(String(event.target?.tagName || '').toLowerCase());
                if (isFormControl) return;
                if (isModifier && key === 'z') {
                    event.preventDefault();
                    event.shiftKey ? this.redo() : this.undo();
                }
                if (isModifier && key === 'y') {
                    event.preventDefault();
                    this.redo();
                }
                if (!isModifier && (key === 'delete' || key === 'backspace')) {
                    event.preventDefault();
                    this.remove();
                }
            };
            window.addEventListener('keydown', this.keyboardHandler);
            this.$watch('templateJsonText', () => {
                const next = this.parseJson(this.templateJsonText);
                if (JSON.stringify(next) !== JSON.stringify(this.templateJson)) {
                    this.templateJson = next;
                    this.render();
                }
            });
        },
        destroy() {
            if (this.keyboardHandler) {
                window.removeEventListener('keydown', this.keyboardHandler);
            }
            this.stage?.destroy();
        },
        render(selectKey = null) {
            const width = Number(this.templateJson.widthMm || this.widthMm) * this.scale;
            const height = Number(this.templateJson.heightMm || this.heightMm) * this.scale;
            const container = document.getElementById('label-stage');
            if (!container) return;
            container.innerHTML = '';
            this.stage = new Konva.Stage({ container: 'label-stage', width, height });
            this.layer = new Konva.Layer();
            this.stage.add(this.layer);
            this.layer.add(new Konva.Rect({ x: 0, y: 0, width, height, fill: '#fff', stroke: '#2563eb', strokeWidth: 1.5, listening: false }));
            this.layer.add(new Konva.Rect({ x: 8, y: 8, width: Math.max(0, width - 16), height: Math.max(0, height - 16), stroke: '#dbeafe', dash: [4, 4], listening: false }));
            (this.templateJson.elements || []).sort((a, b) => (a.layerOrder || 0) - (b.layerOrder || 0)).forEach((element) => this.drawElement(element));
            this.transformer = new Konva.Transformer({
                rotateEnabled: true,
                enabledAnchors: ['top-left', 'top-right', 'bottom-left', 'bottom-right', 'middle-left', 'middle-right', 'top-center', 'bottom-center'],
                boundBoxFunc: (oldBox, newBox) => {
                    if (newBox.width < 8 || newBox.height < 6) return oldBox;
                    return newBox;
                },
            });
            this.layer.add(this.transformer);
            this.stage.on('click tap', (event) => {
                if (event.target === this.stage) {
                    this.selected = null;
                    this.selectedElement = null;
                    this.transformer.nodes([]);
                }
            });
            this.layer.draw();
            this.syncJsonText();
            this.validateLocal();
            const keyToSelect = selectKey || this.selectedElement?.key;
            if (keyToSelect) {
                const node = this.layer.findOne(`.${keyToSelect}`);
                if (node) this.select(node);
            }
        },
        drawElement(element) {
            const attrs = {
                x: Number(element.x) * this.scale,
                y: Number(element.y) * this.scale,
                width: Number(element.width) * this.scale,
                height: Number(element.height) * this.scale,
                draggable: true,
                rotation: element.rotation || 0,
                name: element.key,
            };
            let node;
            if (element.type === 'rectangle') {
                node = new Konva.Rect({ ...attrs, stroke: '#0f172a', strokeWidth: Number(element.borderWidth || 1), fill: element.fill || 'transparent' });
            } else if (element.type === 'line') {
                node = new Konva.Rect({ ...attrs, fill: '#0f172a', stroke: '#0f172a', strokeWidth: 0 });
            } else if (element.type === 'barcode' || element.type === 'qr') {
                node = new Konva.Group({ x: attrs.x, y: attrs.y, width: attrs.width, height: attrs.height, draggable: true, rotation: attrs.rotation, name: element.key });
                node.add(new Konva.Rect({ x: 0, y: 0, width: attrs.width, height: attrs.height, stroke: '#111827', fill: '#f8fafc' }));
                const bars = Math.max(10, Math.floor(attrs.width / 6));
                for (let index = 0; index < bars; index += 1) {
                    const barWidth = index % 3 === 0 ? 3 : 1.5;
                    node.add(new Konva.Rect({ x: 5 + index * 5, y: 4, width: barWidth, height: Math.max(4, attrs.height - 13), fill: '#111827', listening: false }));
                }
                node.add(new Konva.Text({ x: 4, y: Math.max(2, attrs.height - 9), width: attrs.width - 8, text: element.type === 'qr' ? 'QR' : 'BARCODE', fontSize: 7, align: 'center', fill: '#334155', listening: false }));
            } else if (element.type === 'image') {
                node = new Konva.Group({ x: attrs.x, y: attrs.y, width: attrs.width, height: attrs.height, draggable: true, rotation: attrs.rotation, name: element.key });
                node.add(new Konva.Rect({ x: 0, y: 0, width: attrs.width, height: attrs.height, stroke: '#94a3b8', dash: [3, 3], fill: '#fff' }));
                node.add(new Konva.Text({ x: 3, y: Math.max(3, attrs.height / 2 - 5), width: Math.max(10, attrs.width - 6), text: 'LOGO / IMAGE', fontSize: 9, align: 'center', fill: '#334155', listening: false }));

                if (element.imageUrl) {
                    const image = new Image();
                    image.crossOrigin = 'anonymous';
                    image.onload = () => {
                        const konvaImage = new Konva.Image({ image, x: 2, y: 2, width: Math.max(4, attrs.width - 4), height: Math.max(4, attrs.height - 4), listening: false });
                        node.findOne('Text')?.destroy();
                        node.add(konvaImage);
                        this.layer.batchDraw();
                    };
                    image.src = element.imageUrl;
                }
            } else {
                const fontFamily = this.resolveFontFamily(element.style?.fontFamily);
                const fontWeight = element.style?.fontWeight || '600';
                const fontStyle = `${element.style?.fontStyle === 'italic' ? 'italic ' : ''}${['700', '800', 'bold'].includes(String(fontWeight)) ? 'bold' : 'normal'}`.trim();
                node = new Konva.Text({
                    ...attrs,
                    text: this.displayText(element),
                    fontSize: (element.style?.fontSize || 10) * this.scale / 3,
                    fontFamily,
                    fontStyle,
                    align: element.style?.align || 'left',
                    fill: '#0f172a',
                    padding: 2,
                    verticalAlign: 'middle',
                });
            }
            node.on('click tap', () => this.select(node));
            node.on('dragstart transformstart', () => this.beginNodeEdit());
            node.on('dragend transformend', () => this.persistNode(node, true));
            this.layer.add(node);
        },
        select(node) {
            this.selected = node;
            this.selectedElement = this.findElement(node.name());
            if (this.selectedElement && !this.selectedElement.style) {
                this.selectedElement.style = {
                    fontSize: 10,
                    prefixFontSize: 10,
                    suffixFontSize: 10,
                    fontFamily: 'Arial',
                    fontWeight: '600',
                    fontStyle: 'normal',
                    align: 'left',
                };
            }
            const canResize = ['barcode', 'image', 'rectangle', 'line'].includes(this.selectedElement?.type);
            this.transformer.resizeEnabled(canResize);
            this.transformer.enabledAnchors(canResize
                ? ['top-left', 'top-right', 'bottom-left', 'bottom-right', 'middle-left', 'middle-right', 'top-center', 'bottom-center']
                : []);
            this.transformer.nodes([node]);
            this.layer.batchDraw();
        },
        beginNodeEdit() {
            if (!this.activeEditSnapshot) {
                this.activeEditSnapshot = this.clone(this.templateJson);
            }
        },
        persistNode(node, validate = true) {
            const key = node.name();
            const element = (this.templateJson.elements || []).find((item) => item.key === key);
            if (!element) return;
            if (this.activeEditSnapshot) {
                this.remember(this.activeEditSnapshot);
                this.activeEditSnapshot = null;
            }
            const grid = Number(this.templateJson.gridMm || 1);
            const widthMm = Number(this.templateJson.widthMm || this.widthMm);
            const heightMm = Number(this.templateJson.heightMm || this.heightMm);
            const rawWidth = Math.abs(node.width() * node.scaleX());
            const rawHeight = Math.abs(node.height() * node.scaleY());
            element.width = Math.max(2, this.snap(rawWidth / this.scale, grid));
            element.height = Math.max(2, this.snap(rawHeight / this.scale, grid));
            element.x = this.clamp(this.snap(node.x() / this.scale, grid), 0, Math.max(0, widthMm - element.width));
            element.y = this.clamp(this.snap(node.y() / this.scale, grid), 0, Math.max(0, heightMm - element.height));
            element.rotation = node.rotation();
            node.scaleX(1);
            node.scaleY(1);
            this.selectedElement = element;
            this.commit(validate);
            if (validate) this.validateLocal();
        },
        addText() {
            this.addElement({ type: 'text', text: 'Static text' });
        },
        addBinding(bindingKey, label = null) {
            this.addElement({
                type: 'binding_text',
                bindingKey,
                text: label || bindingKey,
                previewValue: this.previewValueForBinding(bindingKey, label),
                width: 42,
                height: 8,
            });
        },
        addBarcode() {
            if ((this.templateJson.elements || []).some((item) => item.type === 'barcode')) {
                this.warnings = [{ type: 'single_barcode_only' }];
                return;
            }
            this.addElement({ type: 'barcode', bindingKey: 'barcode.value', width: 45, height: 16 });
        },
        addRect() {
            this.addElement({ type: 'rectangle', width: 30, height: 15 });
        },
        addLine() {
            this.addElement({ type: 'line', width: Math.min(45, Number(this.templateJson.widthMm || this.widthMm) - 8), height: 1 });
        },
        addElement(partial) {
            this.remember();
            const index = (this.templateJson.elements || []).length + 1;
            const element = {
                key: `element_${Date.now()}`,
                x: 5,
                y: 5 + index * 5,
                width: 35,
                height: 8,
                layerOrder: index,
                style: { fontSize: 10, prefixFontSize: 10, suffixFontSize: 10, fontFamily: 'Arial', fontWeight: '600', align: 'left' },
                ...partial,
            };
            this.templateJson = { ...this.templateJson, elements: [...(this.templateJson.elements || []), element] };
            this.selectedElement = element;
            this.commit(true);
        },
        duplicate() {
            if (!this.selected) return;
            const original = this.templateJson.elements.find((item) => item.key === this.selected.name());
            if (!original) return;
            if (original.type === 'barcode') {
                this.warnings = [{ type: 'single_barcode_only' }];
                return;
            }
            this.remember();
            const copy = { ...original, key: `element_${Date.now()}`, x: original.x + 3, y: original.y + 3, layerOrder: (this.templateJson.elements || []).length + 1 };
            this.templateJson = { ...this.templateJson, elements: [...this.templateJson.elements, copy] };
            this.selectedElement = copy;
            this.commit(true);
        },
        remove() {
            if (!this.selected) return;
            if (this.selected.name() === 'barcode') {
                this.warnings = [{ type: 'barcode_mandatory' }];
                return;
            }
            this.remember();
            this.templateJson = { ...this.templateJson, elements: this.templateJson.elements.filter((item) => item.key !== this.selected.name()) };
            this.selected = null;
            this.selectedElement = null;
            this.commit(true);
        },
        zoomIn() {
            this.scale += 1;
            this.render();
        },
        zoomOut() {
            this.scale = Math.max(2, this.scale - 1);
            this.render();
        },
        setSize() {
            this.remember();
            if (this.size === '50x75') { this.widthMm = 75; this.heightMm = 50; }
            if (this.size === '75x75') { this.widthMm = 75; this.heightMm = 75; }
            if (this.size === '75x100') { this.widthMm = 75; this.heightMm = 100; }
            if (this.size === '100x100') { this.widthMm = 100; this.heightMm = 100; }
            if (this.size === '100x150') { this.widthMm = 100; this.heightMm = 150; }
            this.templateJson = { ...this.templateJson, widthMm: this.widthMm, heightMm: this.heightMm };
            this.commit(true);
        },
        syncSize(widthMm, heightMm) {
            this.remember();
            this.widthMm = Number(widthMm);
            this.heightMm = Number(heightMm);
            this.templateJson = { ...this.templateJson, widthMm: this.widthMm, heightMm: this.heightMm };
            this.commit(true);
        },
        validateLocal() {
            const width = Number(this.templateJson.widthMm || this.widthMm);
            const height = Number(this.templateJson.heightMm || this.heightMm);
            const warnings = (this.templateJson.elements || [])
                .filter((element) => element.x < 0 || element.y < 0 || element.x + element.width > width || element.y + element.height > height)
                .map((element) => ({ type: 'out_of_bounds', element: element.key }));
            if ((this.templateJson.elements || []).filter((element) => element.type === 'barcode').length !== 1) {
                warnings.push({ type: 'one_barcode_required' });
            }
            this.warnings = warnings;
        },
        syncJsonText() {
            this.jsonText = JSON.stringify(this.templateJson, null, 2);
            this.templateJsonText = this.jsonText;
        },
        loadJson() {
            this.remember();
            this.templateJson = this.parseJson(this.jsonText);
            this.commit(true);
        },
        commit(shouldRender = false) {
            this.syncJsonText();
            if (this.$wire) {
                this.$wire.set('templateJsonText', this.templateJsonText, false);
            }
            if (shouldRender) {
                this.render();
            }
        },
        parseJson(value) {
            try {
                return typeof value === 'string' ? JSON.parse(value) : value || {};
            } catch (error) {
                this.warnings = [{ type: 'invalid_json' }];
                return this.templateJson || {};
            }
        },
        snap(value, grid) {
            return Math.round(value / grid) * grid;
        },
        clamp(value, min, max) {
            return Math.min(max, Math.max(min, value));
        },
        findElement(key) {
            return (this.templateJson.elements || []).find((item) => item.key === key) || null;
        },
        displayText(element) {
            const value = element.type === 'binding_text'
                ? (element.previewValue || this.previewValueForBinding(element.bindingKey, element.text))
                : (element.text || 'Text');
            return `${element.prefix || ''}${value}${element.suffix || ''}`;
        },
        previewValueForBinding(bindingKey, label = null) {
            const examples = {
                'company.name': 'Company name',
                'product.name': 'Product name',
                'serial.number': '1',
                'date.current': '23/07/2026',
                'time.current': '14:30',
                'weight.gross': '30.500',
                'weight.tare': '0.800',
                'weight.net': '29.700',
                'pieces.quantity': '10',
                'barcode.value': 'PHK123456',
            };
            if (examples[bindingKey]) return examples[bindingKey];
            const cleanLabel = String(label || bindingKey || 'Value')
                .replace(/^dynamic\.product_variant\./, '')
                .replace(/^dynamic\.product\./, '')
                .replace(/[_-]+/g, ' ')
                .trim();
            if (/colou?r/i.test(cleanLabel)) return 'Red';
            if (/size|width|height|length|dimension/i.test(cleanLabel)) return '10 mm';
            if (/gsm|micron|mtr|meter/i.test(cleanLabel)) return '350';
            if (/quality|grade/i.test(cleanLabel)) return 'Premium';
            return 'Value';
        },
        resolveFontFamily(fontFamily) {
            const map = {
                'Sans Serif': 'Arial',
                Roman: 'Times New Roman',
                Serif: 'Georgia',
                Typewriter: 'Courier New',
                Mono: 'Courier New',
                Condensed: 'Arial Narrow',
                'OCR-B': 'Courier New',
                'TSPL Font 1': 'Arial',
                'TSPL Font 2': 'Arial',
                'TSPL Font 3': 'Courier New',
                'TSPL Font 4': 'Times New Roman',
                'TSPL 1 - 8x12': 'Arial',
                'TSPL 2 - 12x20': 'Arial',
                'TSPL 3 - 16x24': 'Courier New',
                'TSPL 4 - 24x32': 'Times New Roman',
                'TSPL 5 - 32x48': 'Arial Black',
                'TSPL TSS24.BF2': 'Arial',
                'TSPL TST24.BF2': 'Times New Roman',
                'TSPL K': 'Arial',
                'TSPL OCR-A': 'Courier New',
                'TSPL OCR-B': 'Courier New',
            };

            return map[fontFamily] || fontFamily || 'Arial';
        },
        updateSelected(path, value) {
            if (!this.selectedElement) return;
            const element = this.findElement(this.selectedElement.key);
            if (!element) return;
            this.remember();
            if (path.startsWith('style.')) {
                const key = path.replace('style.', '');
                element.style = { ...(element.style || {}), [key]: value };
            } else {
                element[path] = ['x', 'y', 'width', 'height', 'rotation', 'layerOrder'].includes(path) ? Number(value) : value;
            }
            this.selectedElement = element;
            this.commit(true);
        },
        nudge(dx, dy) {
            if (!this.selectedElement) return;
            this.remember();
            const element = this.findElement(this.selectedElement.key);
            if (!element) return;
            element.x = Number(element.x || 0) + dx;
            element.y = Number(element.y || 0) + dy;
            this.selectedElement = element;
            this.commit(true);
        },
        resizeSelected(dw, dh) {
            if (!this.selectedElement) return;
            this.remember();
            const element = this.findElement(this.selectedElement.key);
            if (!element) return;
            element.width = Math.max(2, Number(element.width || 2) + dw);
            element.height = Math.max(2, Number(element.height || 2) + dh);
            this.selectedElement = element;
            this.commit(true);
        },
        changeFontSize(delta) {
            if (!this.selectedElement || ['barcode', 'image', 'rectangle', 'line'].includes(this.selectedElement.type)) return;
            const current = Number(this.selectedElement.style?.fontSize || 10);
            this.updateSelected('style.fontSize', Math.min(72, Math.max(4, current + delta)));
        },
        rotateSelected(delta) {
            if (!this.selectedElement) return;
            const current = Number(this.selectedElement.rotation || 0);
            this.updateSelected('rotation', current + delta);
        },
        layerSelected(delta) {
            if (!this.selectedElement) return;
            const current = Number(this.selectedElement.layerOrder || 0);
            this.updateSelected('layerOrder', Math.max(1, current + delta));
        },
        fitText() {
            if (!this.selectedElement || ['barcode', 'image', 'rectangle', 'line'].includes(this.selectedElement.type)) return;
            this.remember();
            const element = this.findElement(this.selectedElement.key);
            if (!element) return;
            const label = this.displayText(element);
            const width = Number(element.width || 10);
            const height = Number(element.height || 6);
            const estimated = Math.floor(Math.min((width * 2.4) / Math.max(1, label.length / 10), height * 1.15));
            element.style = { ...(element.style || {}), fontSize: Math.min(24, Math.max(5, estimated)) };
            this.selectedElement = element;
            this.commit(true);
        },
        remember(snapshot = null) {
            if (this.isApplyingHistory) return;
            const state = this.clone(snapshot || this.templateJson);
            if (!state || Object.keys(state).length === 0) return;
            const encoded = JSON.stringify(state);
            if (this.history.length && JSON.stringify(this.history[this.history.length - 1]) === encoded) return;
            this.history.push(state);
            if (this.history.length > this.historyLimit) this.history.shift();
            this.future = [];
        },
        undo() {
            if (!this.history.length) return;
            const previous = this.history.pop();
            this.future.push(this.clone(this.templateJson));
            this.applyHistory(previous);
        },
        redo() {
            if (!this.future.length) return;
            const next = this.future.pop();
            this.history.push(this.clone(this.templateJson));
            this.applyHistory(next);
        },
        applyHistory(state) {
            this.isApplyingHistory = true;
            this.templateJson = this.clone(state);
            this.selected = null;
            this.selectedElement = null;
            this.commit(true);
            this.isApplyingHistory = false;
        },
        clone(value) {
            return JSON.parse(JSON.stringify(value || {}));
        },
    };
};
