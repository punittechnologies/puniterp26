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
        scale: 4,
        size: '75x75',
        warnings: [],
        jsonText: '',
        init() {
            this.templateJson = this.parseJson(this.templateJsonText);
            this.render();
            this.$watch('templateJsonText', () => {
                const next = this.parseJson(this.templateJsonText);
                if (JSON.stringify(next) !== JSON.stringify(this.templateJson)) {
                    this.templateJson = next;
                    this.render();
                }
            });
        },
        render() {
            const width = Number(this.templateJson.widthMm || this.widthMm) * this.scale;
            const height = Number(this.templateJson.heightMm || this.heightMm) * this.scale;
            document.getElementById('label-stage').innerHTML = '';
            this.stage = new Konva.Stage({ container: 'label-stage', width, height });
            this.layer = new Konva.Layer();
            this.stage.add(this.layer);
            this.layer.add(new Konva.Rect({ x: 0, y: 0, width, height, stroke: '#2563eb', dash: [6, 4], listening: false }));
            (this.templateJson.elements || []).sort((a, b) => (a.layerOrder || 0) - (b.layerOrder || 0)).forEach((element) => this.drawElement(element));
            this.transformer = new Konva.Transformer({ rotateEnabled: true });
            this.layer.add(this.transformer);
            this.layer.draw();
            this.syncJsonText();
            this.validateLocal();
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
                node = new Konva.Rect({ ...attrs, stroke: '#0f172a', strokeWidth: 1 });
            } else if (element.type === 'line') {
                node = new Konva.Line({ points: [attrs.x, attrs.y, attrs.x + attrs.width, attrs.y], stroke: '#0f172a', strokeWidth: 1, draggable: true, name: element.key });
            } else if (element.type === 'barcode' || element.type === 'qr') {
                node = new Konva.Rect({ ...attrs, stroke: '#111827', fill: '#f8fafc' });
                this.layer.add(node);
                this.layer.add(new Konva.Text({ x: attrs.x + 4, y: attrs.y + 4, text: element.type.toUpperCase(), fontSize: 10, listening: false }));
            } else {
                node = new Konva.Text({
                    ...attrs,
                    text: element.text || element.bindingKey || 'Text',
                    fontSize: (element.style?.fontSize || 10) * this.scale / 3,
                    fontStyle: element.style?.fontWeight === 'bold' ? 'bold' : 'normal',
                    fill: '#0f172a',
                });
            }
            node.on('click tap', () => this.select(node));
            node.on('dragend transformend', () => this.persistNode(node));
            this.layer.add(node);
        },
        select(node) {
            this.selected = node;
            this.transformer.nodes([node]);
        },
        persistNode(node) {
            const key = node.name();
            const element = (this.templateJson.elements || []).find((item) => item.key === key);
            if (!element) return;
            const grid = Number(this.templateJson.gridMm || 2.5);
            element.x = this.snap(node.x() / this.scale, grid);
            element.y = this.snap(node.y() / this.scale, grid);
            element.width = Math.max(2, this.snap((node.width() * node.scaleX()) / this.scale, grid));
            element.height = Math.max(2, this.snap((node.height() * node.scaleY()) / this.scale, grid));
            element.rotation = node.rotation();
            node.scaleX(1);
            node.scaleY(1);
            this.commit();
            this.validateLocal();
        },
        addText() {
            this.addElement({ type: 'text', text: 'Static text' });
        },
        addBinding(bindingKey) {
            this.addElement({ type: 'binding_text', bindingKey });
        },
        addBarcode() {
            this.addElement({ type: 'barcode', bindingKey: 'barcode.value', width: 45, height: 16 });
        },
        addRect() {
            this.addElement({ type: 'rectangle', width: 30, height: 15 });
        },
        addElement(partial) {
            const index = (this.templateJson.elements || []).length + 1;
            const element = { key: `element_${Date.now()}`, x: 5, y: 5 + index * 5, width: 35, height: 8, layerOrder: index, style: { fontSize: 10 }, ...partial };
            this.templateJson = { ...this.templateJson, elements: [...(this.templateJson.elements || []), element] };
            this.commit(true);
        },
        duplicate() {
            if (!this.selected) return;
            const original = this.templateJson.elements.find((item) => item.key === this.selected.name());
            if (!original) return;
            this.templateJson = { ...this.templateJson, elements: [...this.templateJson.elements, { ...original, key: `element_${Date.now()}`, x: original.x + 3, y: original.y + 3 }] };
            this.commit(true);
        },
        remove() {
            if (!this.selected) return;
            this.templateJson = { ...this.templateJson, elements: this.templateJson.elements.filter((item) => item.key !== this.selected.name()) };
            this.selected = null;
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
            if (this.size === '50x75') { this.widthMm = 50; this.heightMm = 75; }
            if (this.size === '75x75') { this.widthMm = 75; this.heightMm = 75; }
            if (this.size === '100x100') { this.widthMm = 100; this.heightMm = 100; }
            this.templateJson = { ...this.templateJson, widthMm: this.widthMm, heightMm: this.heightMm };
            this.commit(true);
        },
        validateLocal() {
            const width = Number(this.templateJson.widthMm || this.widthMm);
            const height = Number(this.templateJson.heightMm || this.heightMm);
            this.warnings = (this.templateJson.elements || []).filter((element) => element.x < 0 || element.y < 0 || element.x + element.width > width || element.y + element.height > height).map((element) => ({ type: 'out_of_bounds', element: element.key }));
        },
        syncJsonText() {
            this.jsonText = JSON.stringify(this.templateJson, null, 2);
            this.templateJsonText = this.jsonText;
        },
        loadJson() {
            this.templateJson = this.parseJson(this.jsonText);
            this.commit(true);
        },
        commit(shouldRender = false) {
            this.syncJsonText();
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
    };
};
