//
import Konva from 'konva';

window.labelDesigner = function labelDesigner(templateJsonText, widthMm, heightMm, previewProducts = []) {
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
        previewProducts: Array.isArray(previewProducts) ? previewProducts : [],
        previewProductId: Array.isArray(previewProducts) && previewProducts.length ? previewProducts[0].id : '',
        styleClipboard: null,
        toolSearch: '',
        scale: 4,
        size: '75x75',
        warnings: [],
        jsonText: '',
        history: [],
        future: [],
        historyLimit: 50,
        isApplyingHistory: false,
        activeEditSnapshot: null,
        activeTransformAnchor: '',
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
                if (!isModifier && ['arrowup', 'arrowdown', 'arrowleft', 'arrowright'].includes(key) && this.selectedElement) {
                    event.preventDefault();
                    const distance = event.shiftKey ? 1 : 0.125;
                    if (key === 'arrowup') this.nudge(0, -distance);
                    if (key === 'arrowdown') this.nudge(0, distance);
                    if (key === 'arrowleft') this.nudge(-distance, 0);
                    if (key === 'arrowright') this.nudge(distance, 0);
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
                draggable: element.locked !== true,
                rotation: element.rotation || 0,
                name: element.key,
            };
            let node;
            if (element.type === 'rectangle') {
                node = new Konva.Rect({ ...attrs, stroke: '#0f172a', strokeWidth: Number(element.borderWidth || 1), fill: element.fill || 'transparent' });
            } else if (element.type === 'line') {
                node = new Konva.Rect({ ...attrs, fill: '#0f172a', stroke: '#0f172a', strokeWidth: 0 });
            } else if (element.type === 'qr') {
                node = new Konva.Group({ x: attrs.x, y: attrs.y, width: attrs.width, height: attrs.height, draggable: attrs.draggable, rotation: attrs.rotation, name: element.key });
                node.add(new Konva.Rect({ x: 0, y: 0, width: attrs.width, height: attrs.height, stroke: '#111827', fill: '#fff' }));
                const modules = 21;
                const quiet = Math.max(3, Math.min(attrs.width, attrs.height) * 0.07);
                const cell = Math.max(1, (Math.min(attrs.width, attrs.height) - quiet * 2) / modules);
                const finder = (row, col) => {
                    const zones = [[0, 0], [0, modules - 7], [modules - 7, 0]];
                    return zones.some(([top, left]) => row >= top && row < top + 7 && col >= left && col < left + 7
                        && (row === top || row === top + 6 || col === left || col === left + 6
                            || (row >= top + 2 && row <= top + 4 && col >= left + 2 && col <= left + 4)));
                };
                for (let row = 0; row < modules; row += 1) {
                    for (let col = 0; col < modules; col += 1) {
                        const finderCell = finder(row, col);
                        const dataCell = !finderCell && ((row * 11 + col * 7 + row * col) % 5 < 2);
                        if (finderCell || dataCell) {
                            node.add(new Konva.Rect({ x: quiet + col * cell, y: quiet + row * cell, width: cell + .2, height: cell + .2, fill: '#111827', listening: false }));
                        }
                    }
                }
            } else if (element.type === 'barcode') {
                node = new Konva.Group({ x: attrs.x, y: attrs.y, width: attrs.width, height: attrs.height, draggable: attrs.draggable, rotation: attrs.rotation, name: element.key });
                node.add(new Konva.Rect({ x: 0, y: 0, width: attrs.width, height: attrs.height, stroke: '#111827', fill: '#f8fafc' }));
                const isCustomer = element.bindingKey === 'product.customer_barcode';
                const previewValues = this.currentPreviewValues();
                const sampleValue = String(previewValues[element.bindingKey || 'barcode.value'] || (isCustomer ? '' : 'PHK123456'));
                const caption = String(element.caption || (isCustomer ? 'CUSTOMER SKU' : '')).trim();
                const captionPosition = element.captionPosition || (caption ? 'top' : 'none');
                const captionHeight = caption && captionPosition !== 'none' ? 10 : 0;
                if (isCustomer && !sampleValue) {
                    node.add(new Konva.Text({
                        x: 4,
                        y: Math.max(2, attrs.height / 2 - 8),
                        width: attrs.width - 8,
                        text: 'No customer barcode for this product',
                        fontSize: 8,
                        align: 'center',
                        fill: '#94a3b8',
                        listening: false,
                    }));
                }
                if (caption && captionPosition === 'top') {
                    node.add(new Konva.Text({ x: 3, y: 2, width: attrs.width - 6, text: caption, fontSize: 7, align: 'center', fill: '#0f172a', listening: false }));
                }
                const bars = Math.max(10, Math.floor(attrs.width / 6));
                if (sampleValue) {
                    for (let index = 0; index < bars; index += 1) {
                        const barWidth = index % 3 === 0 ? 3 : 1.5;
                        node.add(new Konva.Rect({ x: 5 + index * 5, y: 4 + (captionPosition === 'top' ? captionHeight : 0), width: barWidth, height: Math.max(4, attrs.height - 13 - captionHeight), fill: '#111827', listening: false }));
                    }
                }
                if (element.showValue !== false && sampleValue) {
                    node.add(new Konva.Text({ x: 4, y: Math.max(2, attrs.height - 9), width: attrs.width - 8, text: sampleValue, fontSize: 7, align: 'center', fill: '#334155', listening: false }));
                }
                if (caption && captionPosition === 'bottom') {
                    node.add(new Konva.Text({ x: 3, y: Math.max(2, attrs.height - (element.showValue === false ? 9 : 17)), width: attrs.width - 6, text: caption, fontSize: 7, align: 'center', fill: '#0f172a', listening: false }));
                }
            } else if (element.type === 'image') {
                node = new Konva.Group({ x: attrs.x, y: attrs.y, width: attrs.width, height: attrs.height, draggable: attrs.draggable, rotation: attrs.rotation, name: element.key });
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
                const analysis = this.analyseTextElement(element);
                const fontFamily = this.templateJson.precision203 ? 'Courier New, monospace' : this.resolveFontFamily(element.style?.fontFamily);
                const fontWeight = element.style?.fontWeight || '600';
                const fontStyle = `${!this.templateJson.precision203 && element.style?.fontStyle === 'italic' ? 'italic ' : ''}${['700', '800', 'bold'].includes(String(fontWeight)) ? 'bold' : 'normal'}`.trim();
                if (analysis.overflow) {
                    this.layer.add(new Konva.Rect({
                        x: attrs.x,
                        y: attrs.y,
                        width: attrs.width,
                        height: attrs.height,
                        stroke: '#dc2626',
                        strokeWidth: 1.5,
                        dash: [4, 3],
                        listening: false,
                    }));
                }
                node = new Konva.Text({
                    ...attrs,
                    text: analysis.visibleLines.join('\n'),
                    fontSize: this.templateJson.precision203
                        ? Math.max(4, analysis.spec.characterHeightDots / 8 * this.scale * 0.78)
                        : (element.style?.fontSize || 10) * this.scale / 3,
                    fontFamily,
                    fontStyle,
                    align: element.style?.align || 'left',
                    fill: analysis.overflow ? '#b91c1c' : '#0f172a',
                    padding: 0,
                    lineHeight: analysis.lineHeightRatio,
                    verticalAlign: 'top',
                    wrap: 'none',
                    ellipsis: false,
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
                    fontFamily: 'TVS Auto',
                    fontWeight: '600',
                    fontStyle: 'normal',
                    align: 'left',
                };
            }
            if (this.selectedElement?.type === 'barcode') {
                this.selectedElement.caption ??= '';
                this.selectedElement.captionPosition ??= this.selectedElement.caption ? 'top' : 'none';
                this.selectedElement.showValue ??= true;
            }
            if (this.selectedElement?.type === 'image') {
                this.selectedElement.preserveAspectRatio ??= true;
            }
            if (this.selectedElement && !['barcode', 'qr', 'image', 'rectangle', 'line'].includes(this.selectedElement.type)) {
                this.selectedElement.multiline ??= Boolean(this.templateJson.precision203);
                this.selectedElement.lineGapMm ??= 0;
                if (this.selectedElement.bindingKey?.startsWith('weight.gross_per_piece.') || this.selectedElement.bindingKey?.startsWith('weight.net_per_piece.')) {
                    this.selectedElement.decimalPrecision ??= 5;
                }
            }
            this.selectedElement.locked ??= false;
            const canResize = this.selectedElement?.locked !== true;
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
            this.activeTransformAnchor = this.transformer?.getActiveAnchor?.() || '';
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
            const activeAnchor = this.activeTransformAnchor || this.transformer?.getActiveAnchor?.() || '';
            const isText = !['barcode', 'qr', 'image', 'rectangle', 'line'].includes(element.type);
            if (isText && ['top-left', 'top-right', 'bottom-left', 'bottom-right'].includes(activeAnchor)) {
                const scaleFactor = Math.max(0.25, Math.min(Math.abs(node.scaleX()), Math.abs(node.scaleY())));
                const currentFontSize = Number(element.style?.fontSize || 10);
                element.style = {
                    ...(element.style || {}),
                    fontSize: Math.min(72, Math.max(4, Math.round(currentFontSize * scaleFactor))),
                };
            }
            let nextWidth = Math.max(2, this.snap(rawWidth / this.scale, grid));
            let nextHeight = Math.max(2, this.snap(rawHeight / this.scale, grid));
            if (element.type === 'qr') {
                const square = Math.max(15, Math.min(nextWidth, nextHeight));
                nextWidth = square;
                nextHeight = square;
            }
            if (element.type === 'image' && element.preserveAspectRatio !== false) {
                const ratio = Math.max(0.01, Number(element.width || 1) / Math.max(0.01, Number(element.height || 1)));
                if (['top-center', 'bottom-center'].includes(activeAnchor)) {
                    nextWidth = nextHeight * ratio;
                } else {
                    nextHeight = nextWidth / ratio;
                }
            }
            element.width = nextWidth;
            element.height = nextHeight;
            element.x = this.clamp(this.snap(node.x() / this.scale, grid), 0, Math.max(0, widthMm - element.width));
            element.y = this.clamp(this.snap(node.y() / this.scale, grid), 0, Math.max(0, heightMm - element.height));
            element.rotation = node.rotation();
            node.scaleX(1);
            node.scaleY(1);
            this.activeTransformAnchor = '';
            this.selectedElement = element;
            this.commit(validate);
            if (validate) this.validateLocal();
        },
        addText() {
            this.addElement({ type: 'text', text: 'Static text' });
        },
        addBinding(bindingKey, label = null, options = {}) {
            this.addElement({
                type: 'binding_text',
                bindingKey,
                text: label || bindingKey,
                previewValue: this.previewValueForBinding(bindingKey, label),
                width: 42,
                height: 8,
                ...options,
            });
        },
        addBarcode() {
            if ((this.templateJson.elements || []).some((item) => item.type === 'barcode' && (item.bindingKey || 'barcode.value') === 'barcode.value')) {
                this.warnings = [{ type: 'single_barcode_only' }];
                return;
            }
            this.addElement({ type: 'barcode', bindingKey: 'barcode.value', width: 45, height: 16 });
        },
        addCustomerBarcode() {
            if ((this.templateJson.elements || []).some((item) => item.type === 'barcode' && item.bindingKey === 'product.customer_barcode')) {
                this.warnings = [{ type: 'single_customer_barcode_only' }];
                return;
            }
            this.addElement({
                type: 'barcode',
                bindingKey: 'product.customer_barcode',
                caption: '',
                captionPosition: 'top',
                showValue: true,
                width: 45,
                height: 20,
            });
        },
        addQr() {
            if ((this.templateJson.elements || []).some((item) => item.type === 'qr')) {
                this.warnings = [{ type: 'single_qr_only' }];
                return;
            }
            this.addElement({ type: 'qr', bindingKey: 'qr.value', width: 22, height: 22 });
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
                multiline: true,
                locked: false,
                preserveAspectRatio: true,
                lineGapMm: 0,
                style: { fontSize: 10, prefixFontSize: 10, suffixFontSize: 10, fontFamily: 'TVS Auto', fontWeight: '600', align: 'left' },
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
                this.warnings = [{ type: 'single_barcode_source_only' }];
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
            if (this.selectedElement?.type === 'barcode'
                && (this.selectedElement.bindingKey || 'barcode.value') !== 'product.customer_barcode') {
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
            this.scale = Math.min(8, this.scale + 1);
            this.render();
        },
        zoomOut() {
            this.scale = Math.max(2, this.scale - 1);
            this.render();
        },
        resetZoom() {
            this.scale = 4;
            this.render();
        },
        zoomLabel() {
            return `${Math.round((this.scale / 4) * 100)}%`;
        },
        toolMatches(label) {
            const search = String(this.toolSearch || '').trim().toLowerCase();

            return search === '' || String(label || '').toLowerCase().includes(search);
        },
        matchingProductDetailCount(labels) {
            return (Array.isArray(labels) ? labels : []).filter((label) => this.toolMatches(label)).length;
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
            const barcodes = (this.templateJson.elements || []).filter((element) => element.type === 'barcode');
            if (barcodes.filter((element) => (element.bindingKey || 'barcode.value') === 'barcode.value').length !== 1) {
                warnings.push({ type: 'one_barcode_required' });
            }
            if (barcodes.filter((element) => element.bindingKey === 'product.customer_barcode').length > 1 || barcodes.length > 2) {
                warnings.push({ type: 'one_inventory_and_one_customer_barcode_only' });
            }
            if ((this.templateJson.elements || []).filter((element) => element.type === 'qr').length > 1) {
                warnings.push({ type: 'single_qr_only' });
            }
            (this.templateJson.elements || [])
                .filter((element) => element.type === 'qr' && (Number(element.width) < 15 || Number(element.height) < 15))
                .forEach((element) => warnings.push({ type: 'qr_minimum_15mm', element: element.key }));
            (this.templateJson.elements || [])
                .filter((element) => element.type === 'barcode' && (Number(element.width) < 25 || Number(element.height) < 10))
                .forEach((element) => warnings.push({ type: 'barcode_too_small', element: element.key }));
            if (this.templateJson.precision203) {
                (this.templateJson.elements || [])
                    .filter((element) => !['barcode', 'qr', 'image', 'rectangle', 'line'].includes(element.type))
                    .filter((element) => this.analyseTextElement(element).overflow)
                    .forEach((element) => warnings.push({ type: 'text_overflow', element: element.key }));
            }
            const elements = this.templateJson.elements || [];
            for (let first = 0; first < elements.length; first += 1) {
                for (let second = first + 1; second < elements.length; second += 1) {
                    const a = elements[first];
                    const b = elements[second];
                    if (a.type === 'line' || b.type === 'line') continue;
                    const overlaps = Number(a.x) < Number(b.x) + Number(b.width)
                        && Number(a.x) + Number(a.width) > Number(b.x)
                        && Number(a.y) < Number(b.y) + Number(b.height)
                        && Number(a.y) + Number(a.height) > Number(b.y);
                    const contains = (outer, inner) => Number(inner.x) >= Number(outer.x)
                        && Number(inner.y) >= Number(outer.y)
                        && Number(inner.x) + Number(inner.width) <= Number(outer.x) + Number(outer.width)
                        && Number(inner.y) + Number(inner.height) <= Number(outer.y) + Number(outer.height);
                    const intentionalFrame = (a.type === 'rectangle' && contains(a, b))
                        || (b.type === 'rectangle' && contains(b, a));
                    if (overlaps && !intentionalFrame) {
                        warnings.push({ type: 'overlap', elements: [a.key, b.key] });
                    }
                }
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
            const previewValues = this.currentPreviewValues();
            const value = element.type === 'binding_text'
                ? (previewValues[element.bindingKey] ?? element.previewValue ?? this.previewValueForBinding(element.bindingKey, element.text))
                : (element.text || 'Text');
            return `${element.prefix || ''}${value}${element.suffix || ''}`;
        },
        currentPreviewValues() {
            const selected = this.previewProducts.find((product) => String(product.id) === String(this.previewProductId))
                || this.previewProducts[0];
            return selected?.values || {};
        },
        changePreviewProduct() {
            const selectedKey = this.selectedElement?.key || null;
            this.render(selectedKey);
        },
        printerFontSpec(element, fontSizeOverride = null) {
            const style = element?.style || {};
            const fontSize = Number(fontSizeOverride ?? style.fontSize ?? 10);
            const weight = String(style.fontWeight || '');
            const family = String(style.fontFamily || '');
            let font = null;
            const explicit = family.match(/TSPL(?: Font)?\s*([1-5])/i);
            if (explicit) font = explicit[1];
            if (!font) {
                if (fontSize <= 7) font = '1';
                else if (fontSize <= 10) font = '2';
                else if (fontSize <= 14) font = '3';
                else if (fontSize <= 20) font = '4';
                else font = '5';
            }
            const base = {
                '1': [8, 12],
                '2': [12, 20],
                '3': [16, 24],
                '4': [24, 32],
                '5': [32, 48],
            }[font] || [8, 12];
            const multiplier = 1;
            return {
                font,
                fontSize,
                multiplier,
                characterWidthDots: base[0] * multiplier,
                characterHeightDots: base[1] * multiplier,
            };
        },
        wrapPrinterText(text, charsPerLine, multiline) {
            const normalized = String(text || '').replace(/[\r\n\t]+/g, ' ').replace(/\s+/g, ' ').trim();
            if (!normalized) return [''];
            if (!multiline) return [normalized];
            const lines = [];
            let line = '';
            normalized.split(' ').forEach((word) => {
                let remaining = word;
                while (remaining.length > charsPerLine) {
                    if (line) {
                        lines.push(line);
                        line = '';
                    }
                    lines.push(remaining.slice(0, charsPerLine));
                    remaining = remaining.slice(charsPerLine);
                }
                if (!remaining) return;
                const candidate = line ? `${line} ${remaining}` : remaining;
                if (candidate.length <= charsPerLine) {
                    line = candidate;
                } else {
                    if (line) lines.push(line);
                    line = remaining;
                }
            });
            if (line) lines.push(line);
            return lines.length ? lines : [''];
        },
        analyseTextElement(element, fontSizeOverride = null, includeSuggestion = true) {
            const spec = this.printerFontSpec(element, fontSizeOverride);
            const widthDots = Math.max(1, Math.round(Number(element?.width || 1) * 8));
            const heightDots = Math.max(1, Math.round(Number(element?.height || 1) * 8));
            const lineGapDots = Math.max(0, Math.round(Number(element?.lineGapMm || 0) * 8));
            const lineHeightDots = spec.characterHeightDots + lineGapDots;
            const charsPerLine = Math.max(1, Math.floor(widthDots / spec.characterWidthDots));
            const multiline = element?.multiline === true;
            const maxLines = multiline ? Math.max(1, Math.floor(heightDots / lineHeightDots)) : 1;
            const lines = this.wrapPrinterText(this.displayText(element), charsPerLine, multiline);
            const overflow = lines.length > maxLines || (!multiline && lines[0].length > charsPerLine);
            let suggestedFontSize = spec.fontSize;
            if (overflow && includeSuggestion) {
                for (let candidate = Math.floor(spec.fontSize) - 1; candidate >= 4; candidate -= 1) {
                    const result = this.analyseTextElement(element, candidate, false);
                    if (!result.overflow) {
                        suggestedFontSize = candidate;
                        break;
                    }
                }
            }
            return {
                spec,
                lines,
                visibleLines: lines.slice(0, maxLines).map((line) => line.slice(0, charsPerLine)),
                overflow,
                charsPerLine,
                maxLines,
                lineGapDots,
                lineHeightDots,
                lineHeightRatio: lineHeightDots / spec.characterHeightDots,
                suggestedFontSize,
                summary: `Chosen ${spec.fontSize} → TVS font ${spec.font}, ${spec.characterWidthDots}×${spec.characterHeightDots} dots, ${lineGapDots} dot line gap, ${charsPerLine} characters × ${maxLines} line${maxLines === 1 ? '' : 's'}.`,
            };
        },
        selectedTextAnalysis() {
            if (!this.selectedElement || ['barcode', 'qr', 'image', 'rectangle', 'line'].includes(this.selectedElement.type)) {
                return null;
            }
            return this.analyseTextElement(this.selectedElement);
        },
        useSuggestedFontSize() {
            const analysis = this.selectedTextAnalysis();
            if (!analysis) return;
            this.updateSelected('style.fontSize', analysis.suggestedFontSize);
        },
        warningMessage(warning) {
            const messages = {
                out_of_bounds: 'Object extends outside the printable label',
                one_barcode_required: 'One internal inventory barcode is required',
                one_inventory_and_one_customer_barcode_only: 'Only one inventory and one customer barcode are allowed',
                single_qr_only: 'Only one verification QR is allowed',
                qr_minimum_15mm: 'QR must be at least 15 × 15 mm',
                barcode_too_small: 'Barcode may be too small to scan',
                overlap: 'Two object areas overlap',
                text_overflow: 'Text does not fit; open the field to see the suggested font size',
            };
            return messages[warning?.type] || String(warning?.type || 'Label warning').replaceAll('_', ' ');
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
                'product.customer_barcode': 'CUSTOMER123',
            };
            if (bindingKey?.startsWith('weight.gross_per_piece.')) return '0.30500';
            if (bindingKey?.startsWith('weight.net_per_piece.')) return '0.29700';
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
                element[path] = ['x', 'y', 'width', 'height', 'rotation', 'layerOrder', 'lineGapMm', 'decimalPrecision'].includes(path) ? Number(value) : value;
            }
            if (path === 'lineGapMm') element.lineGapMm = Math.min(10, Math.max(0, Number(element.lineGapMm || 0)));
            if (path === 'decimalPrecision') element.decimalPrecision = Math.min(6, Math.max(0, Math.round(Number(element.decimalPrecision ?? 5))));
            if (['x', 'y', 'width', 'height'].includes(path)) {
                const grid = Number(this.templateJson.gridMm || (this.templateJson.precision203 ? 0.125 : 1));
                element[path] = this.snap(Number(element[path] || 0), grid);
                element.width = Math.max(2, Number(element.width || 2));
                element.height = Math.max(2, Number(element.height || 2));
                element.x = this.clamp(Number(element.x || 0), 0, Math.max(0, Number(this.templateJson.widthMm || this.widthMm) - element.width));
                element.y = this.clamp(Number(element.y || 0), 0, Math.max(0, Number(this.templateJson.heightMm || this.heightMm) - element.height));
            }
            if (element.type === 'qr' && ['width', 'height'].includes(path)) {
                const square = Math.max(15, Number(element[path] || 15));
                element.width = square;
                element.height = square;
            }
            this.selectedElement = element;
            this.commit(true);
        },
        nudge(dx, dy) {
            if (!this.selectedElement || this.selectedElement.locked) return;
            this.remember();
            const element = this.findElement(this.selectedElement.key);
            if (!element) return;
            const grid = Number(this.templateJson.gridMm || (this.templateJson.precision203 ? 0.125 : 1));
            element.x = this.clamp(
                this.snap(Number(element.x || 0) + dx, grid),
                0,
                Math.max(0, Number(this.templateJson.widthMm || this.widthMm) - Number(element.width || 0)),
            );
            element.y = this.clamp(
                this.snap(Number(element.y || 0) + dy, grid),
                0,
                Math.max(0, Number(this.templateJson.heightMm || this.heightMm) - Number(element.height || 0)),
            );
            this.selectedElement = element;
            this.commit(true);
        },
        resizeSelected(dw, dh) {
            if (!this.selectedElement || this.selectedElement.locked) return;
            this.remember();
            const element = this.findElement(this.selectedElement.key);
            if (!element) return;
            element.width = Math.max(2, Number(element.width || 2) + dw);
            element.height = Math.max(2, Number(element.height || 2) + dh);
            this.selectedElement = element;
            this.commit(true);
        },
        changeFontSize(delta) {
            if (!this.selectedElement || ['barcode', 'qr', 'image', 'rectangle', 'line'].includes(this.selectedElement.type)) return;
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
        alignSelected(position) {
            if (!this.selectedElement || this.selectedElement.locked) return;
            const element = this.findElement(this.selectedElement.key);
            if (!element) return;
            const labelWidth = Number(this.templateJson.widthMm || this.widthMm);
            const labelHeight = Number(this.templateJson.heightMm || this.heightMm);
            if (position === 'left') this.updateSelected('x', 2);
            if (position === 'center') this.updateSelected('x', (labelWidth - Number(element.width || 0)) / 2);
            if (position === 'right') this.updateSelected('x', labelWidth - Number(element.width || 0) - 2);
            if (position === 'middle') this.updateSelected('y', (labelHeight - Number(element.height || 0)) / 2);
        },
        copySelectedStyle() {
            if (!this.selectedElement || ['barcode', 'qr', 'image', 'rectangle', 'line'].includes(this.selectedElement.type)) return;
            this.styleClipboard = this.clone(this.selectedElement.style || {});
        },
        pasteSelectedStyle() {
            if (!this.selectedElement || !this.styleClipboard || ['barcode', 'qr', 'image', 'rectangle', 'line'].includes(this.selectedElement.type)) return;
            const element = this.findElement(this.selectedElement.key);
            if (!element) return;
            this.remember();
            element.style = this.clone(this.styleClipboard);
            this.selectedElement = element;
            this.commit(true);
        },
        orderedElements() {
            return [...(this.templateJson.elements || [])].sort((a, b) => Number(b.layerOrder || 0) - Number(a.layerOrder || 0));
        },
        elementLabel(element) {
            if (element.type === 'barcode') return element.bindingKey === 'product.customer_barcode' ? 'Customer barcode' : 'Inventory barcode';
            if (element.type === 'qr') return 'Verification QR';
            return element.bindingKey || element.text || element.type || 'Object';
        },
        selectElementByKey(key) {
            const node = this.layer?.findOne(`.${key}`);
            if (node) this.select(node);
        },
        fitText() {
            this.useSuggestedFontSize();
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

window.reportFilterBuilder = function reportFilterBuilder(products = [], fields = [], selectedProductIds = [], selectedDetails = {}) {
    return {
        products: Array.isArray(products) ? products : [],
        fields: Array.isArray(fields) ? fields : [],
        selectedProductIds: (Array.isArray(selectedProductIds) ? selectedProductIds : []).map(String),
        selectedDetails: Object.fromEntries(Object.entries(selectedDetails || {}).map(([key, values]) => [key, (Array.isArray(values) ? values : [values]).map(String)])),
        detailInputs: {},
        productOpen: false,
        detailOpen: false,
        productSearch: '',
        detailSearch: '',
        filteredProducts() {
            const term = this.productSearch.trim().toLowerCase();
            return this.products.filter((product) => !term || String(product.name).toLowerCase().includes(term));
        },
        filteredFields() {
            const term = this.detailSearch.trim().toLowerCase();
            return this.fields.filter((field) => !term || String(field.field_label).toLowerCase().includes(term));
        },
        productLabel() {
            if (!this.selectedProductIds.length) return 'All products';
            const first = this.products.find((product) => String(product.id) === this.selectedProductIds[0]);
            return `${first?.name || 'Selected product'}${this.selectedProductIds.length > 1 ? ` +${this.selectedProductIds.length - 1}` : ''}`;
        },
        detailLabel() {
            const count = Object.keys(this.selectedDetails).length;
            return count ? `${count} selected` : 'Choose details';
        },
        toggleDetail(key) {
            if (Object.prototype.hasOwnProperty.call(this.selectedDetails, key)) {
                delete this.selectedDetails[key];
            } else {
                this.selectedDetails[key] = [];
            }
            this.selectedDetails = { ...this.selectedDetails };
        },
        detailSelected(key) {
            return Object.prototype.hasOwnProperty.call(this.selectedDetails, key);
        },
        activeDetailFields() {
            return this.fields.filter((field) => this.detailSelected(field.internal_key));
        },
        valuesFor(key) {
            return this.selectedDetails[key] || [];
        },
        addDetailValue(key) {
            const value = String(this.detailInputs[key] || '').trim();
            if (!value) return;
            const values = this.valuesFor(key);
            if (!values.includes(value) && values.length < 20) {
                this.selectedDetails[key] = [...values, value];
                this.selectedDetails = { ...this.selectedDetails };
            }
            this.detailInputs[key] = '';
        },
        removeDetailValue(key, value) {
            this.selectedDetails[key] = this.valuesFor(key).filter((item) => item !== value);
            this.selectedDetails = { ...this.selectedDetails };
        },
        fieldOptions(field) {
            return Array.isArray(field.filter_options) ? field.filter_options : [];
        },
    };
};
